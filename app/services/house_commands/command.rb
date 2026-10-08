module HouseCommands
  class Command
    def self.call(...) = new(...).call

    def call
      undo = UndoAction.capture!(undo_description, undo_light_ids) if undoable?
      result = ActivityRecorder.record(**activity) { send_to_bridge }
      HouseBroadcast.changes(catch_up_mirror)
      Outcome.new(result:, undo:)
    end

    private

    def undoable? = false

    def catch_up_mirror
      Hue.wait_for_bridge
      Hue::Mirror.refresh
    end

    def read_back_lights(light_ids) = Hue::Mirror.apply(light_ids.map { |light_id| Hue.client.lights.find(light_id) })
  end
end
