module Hue
  module Api
    class CommandResult < Data.define(:unreachable_lights)
      def self.delivered = new(unreachable_lights: false)

      def self.combine(results) = new(unreachable_lights: results.any?(&:unreachable_lights?))

      def unreachable_lights? = unreachable_lights
    end
  end
end
