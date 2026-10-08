module Hue
  class Mirror
    class Applier
      def self.payload_class = self::PAYLOAD_CLASS

      def initialize(resource, event:, changes:)
        @payload = self.class.payload_class.new(resource)
        @event = event
        @changes = changes
      end

      private

      attr_reader :payload, :event, :changes
    end
  end
end
