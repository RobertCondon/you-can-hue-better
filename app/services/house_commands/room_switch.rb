module HouseCommands
  class RoomSwitch < Command
    def initialize(group, on:)
      @group = group
      @change = Hue::Api::LightChange.power(on)
    end

    private

    def undoable? = true
    def undo_light_ids = @group.lights.pluck(:id)

    def undo_description
      I18n.t("house_commands.room_switch.description", room: @group.display_name, state: @change.description)
    end

    def activity
      { target_kind: @group.kind, target_id: @group.id, target_name: @group.name, action: @change.description, payload: @change.to_payload }
    end

    def send_to_bridge = Hue.client.grouped_lights.update(@group.grouped_light_id, @change.to_payload)
  end
end
