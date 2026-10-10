module HouseCommands
  class RoomSwitch < Command
    def initialize(group, on:)
      @group = group
      @on = on
    end

    def light_ids = @light_ids ||= @group.lights.pluck(:id)

    def unreachable_description = Toasts.a_light_in(@group.name)

    private

    def activity
      { target_kind: @group.kind, target_id: @group.id, target_name: @group.name, action: @on ? "on" : "off", payload: }
    end

    def send_to_bridge = Hue.client.grouped_lights.update(@group.grouped_light_id, payload)

    def payload = { on: { on: @on } }
  end
end
