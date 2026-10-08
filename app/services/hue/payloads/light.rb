module Hue
  module Payloads
    class Light < Resource
      ON_FIELD = "on"
      DIMMING_FIELD = "dimming"
      BRIGHTNESS_FIELD = "brightness"
      COLOR_FIELD = "color"
      XY_FIELD = "xy"
      X_FIELD = "x"
      Y_FIELD = "y"
      COLOR_TEMPERATURE_FIELD = "color_temperature"
      MIREK_FIELD = "mirek"
      NO_BRIGHTNESS = 0

      def on = raw.dig(ON_FIELD, ON_FIELD)
      def brightness = raw.dig(DIMMING_FIELD, BRIGHTNESS_FIELD)
      def color_x = raw.dig(COLOR_FIELD, XY_FIELD, X_FIELD)
      def color_y = raw.dig(COLOR_FIELD, XY_FIELD, Y_FIELD)
      def mirek = raw.dig(COLOR_TEMPERATURE_FIELD, MIREK_FIELD)

      def full_attributes
        { name:, on:, brightness: brightness || NO_BRIGHTNESS, color_x:, color_y:, mirek: }
      end

      def reported_attributes
        attributes = {}
        attributes[:name] = name if name
        attributes[:on] = on unless on.nil?
        attributes[:brightness] = brightness if brightness
        attributes.merge!(color_x:, color_y:) if raw.dig(COLOR_FIELD, XY_FIELD)
        attributes[:mirek] = mirek if raw[COLOR_TEMPERATURE_FIELD]&.key?(MIREK_FIELD)
        attributes
      end
    end
  end
end
