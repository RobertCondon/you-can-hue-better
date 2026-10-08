class ActivityRecorder
  def self.record(target_kind:, target_id:, target_name:, action:, payload: {}, source: Activity::DASHBOARD, control_event: nil, &command)
    new(target_kind:, target_id:, target_name:, action:, payload:, source:, control_event:).record(&command)
  end

  def initialize(**activity_attributes)
    @activity_attributes = activity_attributes
  end

  def record
    command_result = yield
    log(command_result.unreachable_lights? ? Activity::UNREACHABLE : Activity::OK)
    command_result
  rescue Hue::Error => error
    log(error.message)
    raise
  end

  private

  def log(result) = Activity.create!(**@activity_attributes, result:)
end
