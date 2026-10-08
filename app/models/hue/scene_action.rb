module Hue
  class SceneAction < Record
    FALLBACK_HEX = "#ffd9a0"
    MINIMUM_DOT_STRENGTH = 0.3
    FULL_BRIGHTNESS = 100.0

    belongs_to :scene
    belongs_to :light

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }
    def color? = xy.present? || mirek.present?
    def white? = mirek.present? && xy.nil?

    def white_xy = mirek && Color.hex_to_xy(Color.mirek_to_hex(mirek))

    def to_snapshot = LightSnapshot.from_scene_action(self)

    def hex
      return Color.xy_to_hex(xy[:x], xy[:y]) if xy
      return Color.mirek_to_hex(mirek) if mirek

      FALLBACK_HEX
    end

    def dot_hex
      return House::Light::OFF_TILE unless on

      dot_strength = MINIMUM_DOT_STRENGTH + (1 - MINIMUM_DOT_STRENGTH) * (brightness.to_f / FULL_BRIGHTNESS)
      Color.mix(House::Light::OFF_TILE, hex, dot_strength)
    end

    def hue_angle = Color.hue_angle(hex)
  end
end
