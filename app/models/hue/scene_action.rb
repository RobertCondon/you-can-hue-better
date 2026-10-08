module Hue
  class SceneAction < Record
    belongs_to :scene
    belongs_to :light

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }
    def color? = xy.present? || mirek.present?
    def white? = mirek.present? && xy.nil?

    def white_xy = mirek && Color.hex_to_xy(Color.mirek_to_hex(mirek))

    def hex
      return Color.xy_to_hex(xy[:x], xy[:y]) if xy
      return Color.mirek_to_hex(mirek) if mirek

      Color::WARM_WHITE_HEX
    end

    def hue_angle = Color.hue_angle(hex)
  end
end
