module HouseCommands
  class Settlement
    def initialize(command:, activity:, tab:)
      @command = command
      @activity = activity
      @tab = tab
    end

    def settle
      result = @command.deliver
      unreachable = result.unreachable_lights?
      @activity.settle!(unreachable ? Activity::UNREACHABLE : Activity::OK)
      toast(Toasts.not_responding(@command.unreachable_description)) if unreachable
    rescue Hue::Error => error
      @activity.settle!(error.message)
      toast(error.message)
    rescue StandardError
      @activity.settle!(Toasts.went_wrong(@command.target_name))
      toast(Toasts.went_wrong(@command.target_name))
      raise
    ensure
      broadcast_truth
    end

    private

    def toast(message) = HouseBroadcast.toast_to_tab(@tab, message)

    def broadcast_truth
      changes = caught_up_changes
      changes.lights_changed(@command.light_ids)
      HouseBroadcast.changes(changes)
    end

    def caught_up_changes
      @command.catch_up
    rescue Hue::Error
      Hue::Mirror::Changes.new
    end
  end
end
