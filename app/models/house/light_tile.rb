class House
  class LightTile
    OFF_HEX = "#2b3040"
    DARK_INK = "#15181f"
    LIGHT_INK = "#f3f1ec"
    MINIMUM_COLOUR_STRENGTH = 0.3
    TINT_STRENGTH = 0.18
    FULL_BRIGHTNESS = 100.0
    DARK_INK_FROM_LUMINANCE = 0.35
    NAME_COVERED_FROM_FILL = 35
    LEVEL_COVERED_FROM_FILL = 82

    def initialize(light)
      @light = light
    end

    def tile_hex
      return OFF_HEX unless @light.lit?

      colour_strength = MINIMUM_COLOUR_STRENGTH + (1 - MINIMUM_COLOUR_STRENGTH) * (@light.brightness / FULL_BRIGHTNESS)
      Hue::Color.mix(OFF_HEX, @light.hex, colour_strength)
    end

    def tint_hex = @light.lit? ? Hue::Color.mix(OFF_HEX, @light.hex, TINT_STRENGTH) : OFF_HEX

    def tile_text_hex = Hue::Color.luminance(tile_hex) > DARK_INK_FROM_LUMINANCE ? DARK_INK : LIGHT_INK

    def fill_pct = @light.level

    def name_ink = ink_over_fill(NAME_COVERED_FROM_FILL)

    def level_ink = ink_over_fill(LEVEL_COVERED_FROM_FILL)

    private

    def ink_over_fill(covered_from_fill) = @light.lit? && fill_pct >= covered_from_fill ? tile_text_hex : LIGHT_INK
  end
end
