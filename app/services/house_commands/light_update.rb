module HouseCommands
  class LightUpdate < Command
    ACTIVITY_KIND = "light"
    MIREKS_PER_KELVIN_RECIPROCAL = 1_000_000
    KELVIN_ROUNDING = -2

    def initialize(light, fields)
      @light = light
      @fields = fields
    end

    def light_ids = [ @light.id ]

    private

    def activity
      { target_kind: ACTIVITY_KIND, target_id: @light.id, target_name: @light.name, action: description, payload: }
    end

    def send_to_bridge = Hue.client.lights.update(@light.id, payload)

    def catch_up_mirror = read_back_lights([ @light.id ])

    def payload = @payload ||= requested_payload

    def requested_payload
      return { on: { on: requested_power } } if @fields[:on].present?
      return { on: { on: true }, dimming: { brightness: @fields[:brightness].to_f.clamp(Hue::Api::Limits::LIT_BRIGHTNESS) } } if @fields[:brightness].present?
      return { on: { on: true }, color: { xy: Hue::Color.hex_to_xy(@fields[:color]) } } if @fields[:color].present?
      return { on: { on: true }, color: { xy: { x: cie(@fields[:x]), y: cie(@fields[:y]) } } } if @fields[:x].present? && @fields[:y].present?
      return { on: { on: true }, color_temperature: { mirek: @fields[:mirek].to_i.clamp(Hue::Api::Limits::MIREK) } } if @fields[:mirek].present?

      raise NothingToSend, I18n.t("house_commands.light_update.nothing_to_change")
    end

    def description
      return "colour #{Hue::Color.xy_to_hex(payload[:color][:xy][:x], payload[:color][:xy][:y])}" if payload[:color]
      return "white #{kelvin(payload[:color_temperature][:mirek])}K" if payload[:color_temperature]
      return "brightness #{payload[:dimming][:brightness].round}%" if payload[:dimming]

      payload[:on][:on] ? "on" : "off"
    end

    def requested_power = ActiveModel::Type::Boolean.new.cast(@fields[:on])

    def cie(value) = value.to_f.clamp(Hue::Api::Limits::CIE).round(Hue::Color::Cie::XY_DECIMAL_PLACES)

    def kelvin(mirek) = (MIREKS_PER_KELVIN_RECIPROCAL / mirek).round(KELVIN_ROUNDING)
  end
end
