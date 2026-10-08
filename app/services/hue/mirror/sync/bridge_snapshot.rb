module Hue
  class Mirror
    class Sync
      class BridgeSnapshot
        PAYLOAD_CLASSES = {
          devices: Api::Payloads::Device,
          lights: Api::Payloads::Light,
          rooms: Api::Payloads::Group,
          zones: Api::Payloads::Group,
          grouped_lights: Api::Payloads::GroupedLight,
          scenes: Api::Payloads::Scene,
          smart_scenes: Api::Payloads::Scene,
          buttons: Api::Payloads::Button,
          relative_rotaries: Api::Payloads::RelativeRotary,
          zigbee_connectivity: Api::Payloads::ZigbeeConnectivity,
          device_power: Api::Payloads::DevicePower
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
end
