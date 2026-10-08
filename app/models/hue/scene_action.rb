module Hue
  # What one light does in one scene. Mirror of raw.actions on the scene; rebuilt on every change.
  class SceneAction < Record
    belongs_to :scene
    belongs_to :light

    def xy      = color_x && { x: color_x.to_f, y: color_y.to_f }
    def color?  = xy.present? || mirek.present?

    # The light as it would look in this scene: the same value object the dashboard renders.
    def to_snapshot
      House::Light.new(
        id: light.id, name: light.name, on:, brightness: brightness.to_f, xy: xy || white_xy, owner_id: light.device_id,
        gamut: light.raw.dig("color", "gamut")&.transform_values { _1.symbolize_keys }&.symbolize_keys,
        mirek:, mirek_valid: mirek.present? && xy.nil?, nickname: light.extension&.nickname, reachable: light.device.reachable,
        archetype: light.raw.dig("metadata", "archetype") || light.device.raw.dig("product_data", "product_archetype")
      )
    end

    # Full-brightness colour of this action.
    def hex
      return Hue::Color.xy_to_hex(xy[:x], xy[:y]) if xy
      return Hue::Color.mirek_to_hex(mirek) if mirek
      "#ffd9a0"
    end

    # The colour at the scene's brightness, for dots and swatches.
    def dot_hex = on ? Hue::Color.mix(House::Light::OFF_TILE, hex, 0.3 + 0.7 * (brightness.to_f / 100)) : House::Light::OFF_TILE

    # Hue angle 0..360 for sorting a row of dots into a spectrum.
    def hue_angle = Hue::Color.hue_angle(hex)

    private

    # A white given as a temperature still needs an xy for the tile maths.
    def white_xy
      return nil unless mirek
      Hue::Color.hex_to_xy(Hue::Color.mirek_to_hex(mirek))
    end
  end
end
