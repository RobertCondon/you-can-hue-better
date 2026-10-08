module Hue
  module Payloads
    class SceneAction < Resource
      TARGET_FIELD = "target"
      ACTION_FIELD = "action"

      def light_id = raw.dig(TARGET_FIELD, REFERENCE_ID_FIELD)

      def row_attributes
        light_state = Light.new(raw[ACTION_FIELD].to_h)
        { light_id:, on: light_state.on != false, brightness: light_state.brightness, color_x: light_state.color_x, color_y: light_state.color_y, mirek: light_state.mirek }
      end
    end
  end
end
