module HouseCommands
  class RoomBrightness < Command
    def initialize(group, level)
      @group = group
      @brightness = level.to_f.clamp(Hue::Api::Limits::LIT_BRIGHTNESS)
    end

    def light_ids = @light_ids ||= @group.lights.pluck(:id)

    def unreachable_description = Toasts.a_light_in(@group.name)

    private

    def activity
      { target_kind: @group.kind, target_id: @group.id, target_name: @group.name, action: "brightness #{@brightness.round}%", payload: }
    end

    def send_to_bridge
      return Hue.client.grouped_lights.update(@group.grouped_light_id, payload) if lit_light_ids.empty?

      Hue::Api::CommandResult.combine(lit_light_ids.map { |light_id| Hue.client.lights.update(light_id, payload) })
    end

    def payload = { on: { on: true }, dimming: { brightness: @brightness } }

    def lit_light_ids = @lit_light_ids ||= @group.lights.where(on: true).pluck(:id)
  end
end
