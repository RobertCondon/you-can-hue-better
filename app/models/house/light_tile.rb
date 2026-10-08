class House
  class LightTile
    DARK_INK = "#15181f"
    LIGHT_INK = "#f3f1ec"
    TINT_STRENGTH = 0.18
    DARK_INK_FROM_LUMINANCE = 0.35
    NAME_COVERED_FROM_FILL = 35
    LEVEL_COVERED_FROM_FILL = 82

    def initialize(light)
      @light = light
    end

    def tile_hex = @light.lit? ? Glow.hex(@light.hex, @light.brightness) : Glow::OFF_HEX

    def tint_hex = @light.lit? ? Hue::Color.mix(Glow::OFF_HEX, @light.hex, TINT_STRENGTH) : Glow::OFF_HEX

    def tile_text_hex = Hue::Color.luminance(tile_hex) > DARK_INK_FROM_LUMINANCE ? DARK_INK : LIGHT_INK

    def fill_pct = @light.level

    def name_ink = ink_over_fill(NAME_COVERED_FROM_FILL)

    def level_ink = ink_over_fill(LEVEL_COVERED_FROM_FILL)

    private

    def ink_over_fill(covered_from_fill) = @light.lit? && fill_pct >= covered_from_fill ? tile_text_hex : LIGHT_INK
  end
end
