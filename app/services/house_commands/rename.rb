module HouseCommands
  class Rename < Command
    ACTION_PREFIX = "rename to"

    def initialize(record, new_name)
      @record = record
      @new_name = new_name.to_s.strip
    end

    def call_now = @new_name == @record.name ? nil : super

    private

    def activity
      { target_kind: activity_kind, target_id: @record.id, target_name: @record.name, action: "#{ACTION_PREFIX} #{@new_name}", payload: { name: @new_name } }
    end
  end
end
