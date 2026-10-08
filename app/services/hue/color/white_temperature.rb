module Hue
  module Color
    module WhiteTemperature
      MIREKS_PER_KELVIN_RECIPROCAL = 1_000_000.0
      KELVIN_PER_STEP = 100
      WARM_LIMIT = 66
      NO_BLUE_LIMIT = 19
      COOL_OFFSET = 60
      BLUE_LOG_OFFSET = 10
      RED_COOL_SCALE = 329.698727446
      RED_COOL_EXPONENT = -0.1332047592
      GREEN_WARM_SCALE = 99.4708025861
      GREEN_WARM_OFFSET = 161.1195681661
      GREEN_COOL_SCALE = 288.1221695283
      GREEN_COOL_EXPONENT = -0.0755148492
      BLUE_WARM_SCALE = 138.5177312231
      BLUE_WARM_OFFSET = 305.0447927307

      module_function

      def channels(mirek)
        temperature_step = MIREKS_PER_KELVIN_RECIPROCAL / mirek / KELVIN_PER_STEP
        [ red(temperature_step), green(temperature_step), blue(temperature_step) ].map do |channel|
          channel.round.clamp(Srgb::MIN_CHANNEL, Srgb::MAX_CHANNEL)
        end
      end

      def red(temperature_step)
        return Srgb::MAX_CHANNEL if temperature_step <= WARM_LIMIT

        RED_COOL_SCALE * ((temperature_step - COOL_OFFSET)**RED_COOL_EXPONENT)
      end

      def green(temperature_step)
        return GREEN_WARM_SCALE * Math.log(temperature_step) - GREEN_WARM_OFFSET if temperature_step <= WARM_LIMIT

        GREEN_COOL_SCALE * ((temperature_step - COOL_OFFSET)**GREEN_COOL_EXPONENT)
      end

      def blue(temperature_step)
        return Srgb::MAX_CHANNEL if temperature_step >= WARM_LIMIT
        return Srgb::MIN_CHANNEL if temperature_step <= NO_BLUE_LIMIT

        BLUE_WARM_SCALE * Math.log(temperature_step - BLUE_LOG_OFFSET) - BLUE_WARM_OFFSET
      end
    end
  end
end
