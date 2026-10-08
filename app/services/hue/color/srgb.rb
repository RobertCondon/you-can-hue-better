module Hue
  module Color
    module Srgb
      MIN_CHANNEL = 0
      MAX_CHANNEL = 255
      HEX_PREFIX = "#"
      BLACK_HEX = "#000000"
      SHORTHAND_HEX_LENGTH = 3
      HEX_CHANNEL_DIGITS = /../
      HEX_BASE = 16
      HEX_CHANNEL_FORMAT = "%02x"
      LINEAR_SEGMENT_LIMIT = 0.04045
      LINEAR_SEGMENT_LIMIT_ENCODED = 0.0031308
      LINEAR_SEGMENT_SLOPE = 12.92
      CURVE_OFFSET = 0.055
      CURVE_SCALE = 1.055
      CURVE_EXPONENT = 2.4

      module_function

      def channels_from_hex(hex)
        digits = hex.delete_prefix(HEX_PREFIX)
        digits = digits.chars.map { |digit| digit * 2 }.join if digits.length == SHORTHAND_HEX_LENGTH
        digits.scan(HEX_CHANNEL_DIGITS).map { |channel_digits| channel_digits.to_i(HEX_BASE) }
      end

      def hex_from_channels(channels)
        HEX_PREFIX + channels.map { |channel| Kernel.format(HEX_CHANNEL_FORMAT, channel.clamp(MIN_CHANNEL, MAX_CHANNEL)) }.join
      end

      def linear_channels_from_hex(hex)
        channels_from_hex(hex).map { |channel| linearize(channel.to_f / MAX_CHANNEL) }
      end

      def hex_from_linear_channels(linear_channels)
        hex_from_channels(linear_channels.map { |linear_channel| (encode(linear_channel) * MAX_CHANNEL).round })
      end

      def linearize(encoded_fraction)
        return encoded_fraction / LINEAR_SEGMENT_SLOPE if encoded_fraction <= LINEAR_SEGMENT_LIMIT

        ((encoded_fraction + CURVE_OFFSET) / CURVE_SCALE)**CURVE_EXPONENT
      end

      def encode(linear_fraction)
        return LINEAR_SEGMENT_SLOPE * linear_fraction if linear_fraction <= LINEAR_SEGMENT_LIMIT_ENCODED

        CURVE_SCALE * (linear_fraction**(1 / CURVE_EXPONENT)) - CURVE_OFFSET
      end
    end
  end
end
