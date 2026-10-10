module HouseCommands
  class RoomBrightness < Command
    def initialize(group, level)
      @group = group
      @change = Hue::Api::LightChange.brightness(level)
    end

    def light_ids = @light_ids ||= @group.lights.pluck(:id)

    def unreachable_description = Toasts.a_light_in(@group.name)

    private

    def activity
      { target_kind: @group.kind, target_id: @group.id, target_name: @group.name, action: @change.description, payload: @change.to_payload }
    end

    def send_to_bridge
      return Hue.client.grouped_lights.update(@group.grouped_light_id, @change.to_payload) if lit_light_ids.empty?

      Hue::Api::CommandResult.combine(lit_light_ids.map { |light_id| Hue.client.lights.update(light_id, @change.to_payload) })
    end

    def lit_light_ids = @lit_light_ids ||= @group.lights.where(on: true).pluck(:id)
  end
end
