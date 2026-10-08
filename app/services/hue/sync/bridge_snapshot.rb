module Hue
  class Sync
    class BridgeSnapshot
      PAYLOAD_CLASSES = {
        devices: Payloads::Device,
        lights: Payloads::Light,
        rooms: Payloads::Group,
        zones: Payloads::Group,
        grouped_lights: Payloads::GroupedLight,
        scenes: Payloads::Scene,
        smart_scenes: Payloads::Scene,
        buttons: Payloads::Button,
        relative_rotaries: Payloads::RelativeRotary,
        zigbee_connectivity: Payloads::ZigbeeConnectivity,
        device_power: Payloads::DevicePower
      }.freeze

      def self.fetch(client)
        new(PAYLOAD_CLASSES.to_h do |resource_name, payload_class|
          [ resource_name, client.public_send(resource_name).all.map { |raw| payload_class.new(raw) } ]
        end)
      end

      def initialize(payloads_by_resource)
        @payloads_by_resource = payloads_by_resource
      end

      PAYLOAD_CLASSES.each_key do |resource_name|
        define_method(resource_name) { @payloads_by_resource.fetch(resource_name) }
      end

      def connectivity_of(device_id) = by_owner(:zigbee_connectivity)[device_id]
      def power_of(device_id) = by_owner(:device_power)[device_id]
      def grouped_light_of(group_id) = by_owner(:grouped_lights)[group_id]
      def bridge_home = grouped_lights.find(&:bridge_home?)

      private

      def by_owner(resource_name)
        @by_owner ||= {}
        @by_owner[resource_name] ||= public_send(resource_name).index_by(&:owner_id)
      end
    end
  end
end
