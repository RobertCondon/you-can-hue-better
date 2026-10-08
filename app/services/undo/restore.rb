module Undo
  class Restore
    def initialize(undo_action, client: Hue.client)
      @undo_action = undo_action
      @client = client
    end

    def run
      Hue::CommandResult.combine(@undo_action.light_states.map do |light_state|
        @client.lights.update(light_state.light_id, light_state.restoring_changes)
      end)
    end
  end
end
