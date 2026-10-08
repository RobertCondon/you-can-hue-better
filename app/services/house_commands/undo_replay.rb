module HouseCommands
  class UndoReplay
    ACTIVITY_KIND = "undo"

    def initialize(undo_action)
      @undo_action = undo_action
    end

    def run
      ActivityRecorder.record(target_kind: ACTIVITY_KIND, target_id: @undo_action.id.to_s, target_name: @undo_action.description,
                              action: "#{ACTIVITY_KIND} #{@undo_action.light_count} lights") { Undo::Restore.new(@undo_action).run }
      @undo_action.destroy
    end
  end
end
