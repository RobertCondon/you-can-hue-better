# A light as the bridge reports it right now. Plain Ruby; the view model the dashboard renders.
# (Hue::Light is the database mirror of the same thing.)
class House::Light < Data.define(:id, :name, :on, :brightness, :xy, :owner_id, :gamut, :mirek, :mirek_valid, :nickname, :reachable, :archetype, :hidden, :on_floor, :icon_override)
  OFF_TILE = "#2b3040"
  GAMUT_C  = { red: { x: 0.6915, y: 0.3083 }, green: { x: 0.17, y: 0.7 }, blue: { x: 0.1532, y: 0.0475 } }.freeze

  ICONS = {
    "candle" => %w[candle_bulb],
    "spot"   => %w[spot_bulb ceiling_round ceiling_square recessed_ceiling recessed_floor single_spot double_spot wall_spot],
    "strip"  => %w[hue_lightstrip hue_lightstrip_tv hue_lightstrip_pc string_light christmas_tree]
  }.freeze

  def initialize(gamut: nil, mirek: nil, mirek_valid: false, nickname: nil, reachable: true, archetype: nil, hidden: false, on_floor: true, icon_override: nil, **rest)
    super(gamut: gamut || GAMUT_C, mirek:, mirek_valid: !!mirek_valid, nickname: nickname.presence, reachable: reachable != false, archetype:,
          hidden: !!hidden, on_floor: on_floor != false, icon_override: icon_override.presence, **rest)
  end

  # Which glyph stands for this bulb: lamp, candle, spot or strip, from its Hue archetype.
  def icon      = icon_override || auto_icon
  def auto_icon = ICONS.find { |_, names| names.include?(archetype.to_s) }&.first || "lamp"
  def hidden?   = hidden
  def on_floor? = on_floor

  # The name people see: the dashboard nickname if there is one, else the bridge's name.
  def display_name = nickname || name
  def nicknamed?   = nickname.present?

  def self.from_api(json)
    new(
      id: json["id"],
      name: json.dig("metadata", "name"),
      on: json.dig("on", "on"),
      brightness: json.dig("dimming", "brightness").to_f,
      xy: json.dig("color", "xy")&.symbolize_keys,
      owner_id: json.dig("owner", "rid"),
      gamut: json.dig("color", "gamut")&.transform_values { _1.symbolize_keys }&.symbolize_keys,
      mirek: json.dig("color_temperature", "mirek"),
      mirek_valid: json.dig("color_temperature", "mirek_valid")
    )
  end

  def color?   = xy.present?
  def on?      = on
  def off?     = !on

  # The bridge may think a bulb is on while the bulb has no power. Only a responding bulb is lit.
  def responding? = reachable
  def lit?        = on && reachable

  # "ct" when the bulb is showing a white it was given as a temperature, else "xy".
  def color_mode = mirek_valid ? "ct" : "xy"

  # The light's colour at full brightness.
  def hex = color? ? Hue::Color.xy_to_hex(xy[:x], xy[:y]) : "#ffd9a0"

  # What the tile is painted: the light's colour, dimmed toward the off tile by brightness.
  def tile_hex
    return OFF_TILE unless lit?
    Hue::Color.mix(OFF_TILE, hex, 0.3 + 0.7 * (brightness / 100.0))
  end

  def tile_text_hex = Hue::Color.luminance(tile_hex) > 0.35 ? "#15181f" : "#f3f1ec"

  # The tile grammar: a dim tint of the light's colour as the background, a fill from the left as
  # wide as the brightness in the light's colour, and inks chosen for what sits under each label.
  def tint_hex   = lit? ? Hue::Color.mix(OFF_TILE, hex, 0.18) : OFF_TILE
  # A bulb that is on is never "0%": Hue's lowest step is a fraction of a percent, so it shows as 1%.
  def level      = lit? ? brightness.round.clamp(1, 100) : 0
  def fill_pct   = level
  def name_ink   = lit? && fill_pct >= 35 ? tile_text_hex : "#f3f1ec"
  def level_ink  = lit? && fill_pct >= 82 ? tile_text_hex : "#f3f1ec"

  def brightness_label
    return "Not responding" unless responding?
    off? ? "Off" : "#{level}%"
  end
end
