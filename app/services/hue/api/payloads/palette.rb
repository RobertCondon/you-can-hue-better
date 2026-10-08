module Hue
  module Api
    module Payloads
      class Palette
        COLOR_FIELD = "color"
        COLOR_TEMPERATURE_FIELD = "color_temperature"
        XY_FIELD = "xy"
        X_FIELD = "x"
        Y_FIELD = "y"
        MIREK_FIELD = "mirek"

        def initialize(raw)
          @raw = raw.to_h
        end

        def colour_hexes
          @raw.fetch(COLOR_FIELD, []).map { |entry| Color.xy_to_hex(entry.dig(COLOR_FIELD, XY_FIELD, X_FIELD), entry.dig(COLOR_FIELD, XY_FIELD, Y_FIELD)) }
        end

        def white_hexes
          @raw.fetch(COLOR_TEMPERATURE_FIELD, []).map { |entry| Color.mirek_to_hex(entry.dig(COLOR_TEMPERATURE_FIELD, MIREK_FIELD)) }
        end

        def hexes = colour_hexes + white_hexes
      end
    end
  end
end
