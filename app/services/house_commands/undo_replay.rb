module HouseCommands
  class UndoReplay < Command
    ACTIVITY_KIND = "undo"

    def initialize(undo_action)
      @undo_action = undo_action
    end

    def call = super.tap { @undo_action.destroy }

    private

    def activity
      { target_kind: ACTIVITY_KIND, target_id: @undo_action.id.to_s, target_name: @undo_action.description,
        action: "#{ACTIVITY_KIND} #{@undo_action.light_count} lights" }
    end

    def send_to_bridge
      Hue::Api::CommandResult.combine(@undo_action.light_states.map do |light_state|
        Hue.client.lights.update(light_state.light_id, light_state.change.to_payload)
      end)
    end
  end
end
