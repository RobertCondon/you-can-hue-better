module HouseCommands
  class RenameLight < Rename
    private

    def activity_kind = LightUpdate::ACTIVITY_KIND

    def send_to_bridge
      Hue::Api::CommandResult.combine([ Hue.client.lights.rename(@record.id, @new_name), Hue.client.devices.rename(@record.device_id, @new_name) ])
    end

    def catch_up_mirror
      @record.update!(name: @new_name)
      @record.device.update!(name: @new_name)
      Hue::Mirror::Changes.new.tap { |changes| changes.lights_changed(@record.id) }
    end
  end
end
