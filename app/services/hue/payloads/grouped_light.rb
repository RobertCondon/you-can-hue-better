module Hue
  module Payloads
    class GroupedLight < Light
      BRIDGE_HOME_TYPE = "bridge_home"

      def bridge_home? = owner_type == BRIDGE_HOME_TYPE

      def full_attributes = { any_on: on || false, brightness: brightness || NO_BRIGHTNESS }

      def reported_attributes
        attributes = {}
        attributes[:any_on] = on unless on.nil?
        attributes[:brightness] = brightness if brightness
        attributes
      end
    end
  end
end
