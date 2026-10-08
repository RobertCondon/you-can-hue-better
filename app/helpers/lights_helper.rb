module LightsHelper
  ON_CLASS = "is-on"
  OFF_CLASS = "is-off"
  UNREACHABLE_CLASS = "is-unreachable"

  def light_state_class(light) = class_names(light.lit? ? ON_CLASS : OFF_CLASS, UNREACHABLE_CLASS => !light.responding?)

  def light_power_label(light) = t(light.lit? ? "lights.power.turn_off" : "lights.power.turn_on", light: light.display_name)

  def tile_style(light)
    css_variables(tile: light.tint_hex, fillc: light.tile_hex, fill: "#{light.fill_pct}%", hue: light.hex,
                  ink: light.tile_text_hex, name_ink: light.name_ink, level_ink: light.level_ink)
  end

  def pin_style(light) = css_variables(hue: light.hex, ink: light.tile_text_hex, fill: "#{light.fill_pct}%")

  def scene_light_style(light) = css_variables(tile: light.tile_hex, ink: light.tile_text_hex, hue: light.hex)

  def slider_level(light) = light.lit? ? light.brightness.round : House::Light::UNLIT_LEVEL

  def last_known_state(light)
    light.on? ? t("lights.panel.last_on", level: light.brightness.round) : t("lights.panel.last_off")
  end
end
