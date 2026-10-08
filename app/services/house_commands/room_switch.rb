module HouseCommands
  class RoomSwitch
    ON = "on"
    OFF = "off"

    def initialize(group, on:)
      @group = group
      @on = on
    end

    def run
      changes = { on: { on: @on } }
      Undoable.run(
        description: I18n.t("house_commands.room_switch.description", room: @group.display_name, state: state_word),
        light_ids: @group.lights.pluck(:id),
        activity: { target_kind: @group.kind, target_id: @group.id, target_name: @group.name, action: state_word, payload: changes }
      ) { Hue.client.grouped_lights.update(@group.grouped_light_id, changes) }
    end

    private

    def state_word = @on ? ON : OFF
  end
end
