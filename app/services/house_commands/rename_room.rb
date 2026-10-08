module HouseCommands
  class RenameRoom < Rename
    private

    def activity_kind = @record.kind

    def send_to_bridge = Hue.client.groups_of_type(@record.kind).rename(@record.id, @new_name)

    def catch_up_mirror
      @record.update!(name: @new_name)
      Hue::Mirror::Changes.new.tap { |changes| changes.group_changed(@record.id) }
    end
  end
end
