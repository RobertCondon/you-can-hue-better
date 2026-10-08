class House
  module Glow
    OFF_HEX = "#2b3040"
    MINIMUM_STRENGTH = 0.3
    FULL_BRIGHTNESS = Hue::Api::Limits::BRIGHTNESS.max.to_f

    module_function

    def hex(colour_hex, brightness) = Hue::Color.mix(OFF_HEX, colour_hex, MINIMUM_STRENGTH + (1 - MINIMUM_STRENGTH) * (brightness.to_f / FULL_BRIGHTNESS))
  end
end
