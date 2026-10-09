module HouseCommands
  class LightUpdate < Command
    TOGGLE = "toggle"
    ACTIVITY_KIND = "light"

    def initialize(light, fields)
      @light = light
      @fields = fields
    end

    def light_ids = [ @light.id ]

    private

    def activity
      { target_kind: ACTIVITY_KIND, target_id: @light.id, target_name: @light.name, action: change.description, payload: change.to_payload }
    end

    def send_to_bridge = Hue.client.lights.update(@light.id, change.to_payload)

    def catch_up_mirror = read_back_lights([ @light.id ])

    def change = @change ||= requested_change

    def requested_change
      return Hue::Api::LightChange.power(requested_power) if @fields[:on].present?
      return Hue::Api::LightChange.brightness(@fields[:brightness]) if @fields[:brightness].present?
      return Hue::Api::LightChange.colour(@fields[:color]) if @fields[:color].present?
      return Hue::Api::LightChange.chromaticity(@fields[:x], @fields[:y]) if @fields[:x].present? && @fields[:y].present?
      return Hue::Api::LightChange.white(@fields[:mirek]) if @fields[:mirek].present?

      raise Hue::Error, I18n.t("house_commands.light_update.nothing_to_change")
    end

    def requested_power = @fields[:on] == TOGGLE ? @light.off? : ActiveModel::Type::Boolean.new.cast(@fields[:on])
  end
end
