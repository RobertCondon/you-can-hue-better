module HouseCommands
  module Undoable
    module_function

    def run(description:, light_ids:, activity:, &command)
      undo = Undo::Capture.call(description, light_ids)
      Outcome.new(result: ActivityRecorder.record(**activity, &command), undo:)
    end
  end
end
