module Hue
  module Payloads
    class DevicePower < Resource
      POWER_STATE_FIELD = "power_state"
      BATTERY_LEVEL_FIELD = "battery_level"

      def battery_level = raw.dig(POWER_STATE_FIELD, BATTERY_LEVEL_FIELD)
    end
  end
end
