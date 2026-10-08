class House
  class Light < Data.define(:id, :name, :on, :brightness, :xy, :owner_id, :gamut, :mirek, :mirek_valid, :nickname, :reachable, :archetype, :hidden, :on_floor, :icon_override)
    GAMUT_C = { red: { x: 0.6915, y: 0.3083 }, green: { x: 0.17, y: 0.7 }, blue: { x: 0.1532, y: 0.0475 } }.freeze
    TEMPERATURE_MODE = "ct"
    COLOUR_MODE = "xy"
    LOWEST_LIT_LEVEL = 1
    HIGHEST_LEVEL = 100
    UNLIT_LEVEL = 0
    FULL_BRIGHTNESS = 100.0
    GLOW_DECIMAL_PLACES = 2

    delegate :tile_hex, :tint_hex, :tile_text_hex, :fill_pct, :name_ink, :level_ink, to: :tile

    def initialize(gamut: nil, mirek: nil, mirek_valid: false, nickname: nil, reachable: true, archetype: nil, hidden: false, on_floor: true, icon_override: nil, **attributes)
      super(
        gamut: gamut || GAMUT_C, mirek:, mirek_valid: mirek_valid == true, nickname: nickname.presence, reachable: reachable != false,
        archetype:, hidden: hidden == true, on_floor: on_floor != false, icon_override: icon_override.presence, **attributes
      )
    end

    def display_name = nickname || name
    def nicknamed? = nickname.present?
    def hidden? = hidden
    def on_floor? = on_floor
    def on? = on
    def off? = !on
    def responding? = reachable
    def lit? = on && reachable
    def color? = xy.present?
    def color_mode = mirek_valid ? TEMPERATURE_MODE : COLOUR_MODE

    def icon = icon_override || auto_icon
    def auto_icon = LightIcon.for_archetype(archetype)

    def hex = color? ? Hue::Color.xy_to_hex(xy[:x], xy[:y]) : Hue::Color::WARM_WHITE_HEX

    def level = lit? ? brightness.round.clamp(LOWEST_LIT_LEVEL, HIGHEST_LEVEL) : UNLIT_LEVEL

    def brightness_label
      return I18n.t("house.light.not_responding") unless responding?
      return I18n.t("house.light.off") if off?

      I18n.t("house.light.level", level:)
    end

    def glow = lit? ? (brightness / FULL_BRIGHTNESS).round(GLOW_DECIMAL_PLACES) : UNLIT_LEVEL

    def tile = LightTile.new(self)
  end
end
