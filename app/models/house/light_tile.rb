class House
  class LightTile
    DARK_INK = "#15181f"
    LIGHT_INK = "#f3f1ec"
    TINT_STRENGTH = 0.18
    FILL_STRENGTH = 0.28
    DARK_INK_FROM_LUMINANCE = 0.35

    def initialize(light)
      @light = light
    end

    def tile_hex = @light.lit? ? Glow.hex(@light.hex, @light.brightness) : Glow::OFF_HEX

    def tint_hex = @light.lit? ? Hue::Color.mix(Glow::OFF_HEX, @light.hex, TINT_STRENGTH) : Glow::OFF_HEX

    # The tile's fill keeps one muted shade of the light's colour at every brightness, dark enough for
    # light text; the switch shows the true colour.
    def fill_hex = @light.lit? ? Hue::Color.mix(Glow::OFF_HEX, @light.hex, FILL_STRENGTH) : Glow::OFF_HEX

    def tile_text_hex = Hue::Color.luminance(tile_hex) > DARK_INK_FROM_LUMINANCE ? DARK_INK : LIGHT_INK

    def fill_pct = @light.level
  end
end
