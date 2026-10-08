class LightCommand
  TOGGLE = "toggle"
  ON = "on"
  OFF = "off"
  LOWEST_BRIGHTNESS = 1
  HIGHEST_BRIGHTNESS = 100
  CIE_RANGE = 0..1
  MIREKS_PER_KELVIN_RECIPROCAL = 1_000_000
  KELVIN_ROUNDING = -2

  Command = Data.define(:changes, :description)

  def initialize(light, fields)
    @light = light
    @fields = fields
  end

  def command
    return power if @fields[:on].present?
    return brightness if @fields[:brightness].present?
    return hex_colour if @fields[:color].present?
    return chromaticity if @fields[:x].present? && @fields[:y].present?
    return white if @fields[:mirek].present?

    raise Hue::Error, I18n.t("light_command.nothing_to_change")
  end

  private

  def power
    on = @fields[:on] == TOGGLE ? @light.off? : ActiveModel::Type::Boolean.new.cast(@fields[:on])
    Command.new(changes: { on: { on: } }, description: on ? ON : OFF)
  end

  def brightness
    level = @fields[:brightness].to_f.clamp(LOWEST_BRIGHTNESS, HIGHEST_BRIGHTNESS)
    Command.new(changes: lit(dimming: { brightness: level }), description: "brightness #{level.round}%")
  end

  def hex_colour
    Command.new(changes: lit(color: { xy: Hue::Color.hex_to_xy(@fields[:color]) }), description: "colour #{@fields[:color]}")
  end

  def chromaticity
    point = { x: cie(@fields[:x]), y: cie(@fields[:y]) }
    Command.new(changes: lit(color: { xy: point }), description: "colour #{Hue::Color.xy_to_hex(point[:x], point[:y])}")
  end

  def white
    mirek = @fields[:mirek].to_i.clamp(Hue::Light::MIREK_RANGE)
    kelvin = (MIREKS_PER_KELVIN_RECIPROCAL / mirek).round(KELVIN_ROUNDING)
    Command.new(changes: lit(color_temperature: { mirek: }), description: "white #{kelvin}K")
  end

  def lit(changes) = { on: { on: true } }.merge(changes)

  def cie(value) = value.to_f.clamp(CIE_RANGE).round(Hue::Color::Cie::XY_DECIMAL_PLACES)
end
