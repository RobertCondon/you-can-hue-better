module Hue
  module Color
    module HueAngle
      FULL_TURN_DEGREES = 360
      DEGREES_PER_SECTOR = 60
      SECTOR_COUNT = 6
      GREEN_SECTOR_START = 2
      BLUE_SECTOR_START = 4
      NO_HUE = 0.0

      module_function

      def degrees(channels)
        red, green, blue = channels.map { |channel| channel.to_f / Srgb::MAX_CHANNEL }
        brightest = [ red, green, blue ].max
        spread = brightest - [ red, green, blue ].min
        return NO_HUE if spread.zero?

        angle = DEGREES_PER_SECTOR * sector_position(red, green, blue, brightest, spread)
        angle.negative? ? angle + FULL_TURN_DEGREES : angle
      end

      def sector_position(red, green, blue, brightest, spread)
        if brightest == red then ((green - blue) / spread) % SECTOR_COUNT
        elsif brightest == green then (blue - red) / spread + GREEN_SECTOR_START
        else (red - green) / spread + BLUE_SECTOR_START
        end
      end
    end
  end
end
