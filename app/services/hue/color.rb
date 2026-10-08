module Hue
  module Color
    WARM_WHITE_HEX = "#ffd9a0"

    module_function

    def hex_to_xy(hex) = Cie.xy_from_linear_rgb(Srgb.linear_channels_from_hex(hex))

    def xy_to_hex(cie_x, cie_y)
      return Srgb::BLACK_HEX if cie_y.zero?

      Srgb.hex_from_linear_channels(Cie.linear_rgb_at_full_brightness(cie_x, cie_y))
    end

    def mix(from_hex, to_hex, ratio)
      blended = Srgb.channels_from_hex(from_hex).zip(Srgb.channels_from_hex(to_hex)).map do |from_channel, to_channel|
        (from_channel + (to_channel - from_channel) * ratio).round
      end
      Srgb.hex_from_channels(blended)
    end

    def luminance(hex) = Cie.luminance(Srgb.linear_channels_from_hex(hex))

    def mirek_to_hex(mirek) = Srgb.hex_from_channels(WhiteTemperature.channels(mirek))

    def hue_angle(hex) = HueAngle.degrees(Srgb.channels_from_hex(hex))
  end
end
