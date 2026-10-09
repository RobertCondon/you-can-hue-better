class ActivityRecorder
  def self.record(**activity_attributes, &command) = new(**activity_attributes).record(&command)

  def self.pending(**activity_attributes) = new(**activity_attributes).pending

  def initialize(target_kind:, target_id:, target_name:, action:, payload: {}, source: Activity::DASHBOARD, control_event: nil)
    @activity_attributes = { target_kind:, target_id:, target_name:, action:, payload:, source:, control_event: }
  end

  def record
    command_result = yield
    log(command_result.unreachable_lights? ? Activity::UNREACHABLE : Activity::OK)
    command_result
  rescue Hue::Error => error
    log(error.message)
    raise
  end

  def pending = log(Activity::PENDING)

  private

  def log(result) = Activity.create!(**@activity_attributes, result:)
end
