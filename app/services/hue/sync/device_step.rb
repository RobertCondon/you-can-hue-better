module Hue
  class Sync
    class DeviceStep < Step
      def run
        snapshot.devices.map do |device|
          upsert(Device, device.id,
            name: device.name,
            product_name: device.product_name,
            kind: Device.kind_for(device.product_name, has_light: device.has_light?),
            id_v1: device.legacy_id,
            reachable: reachable?(device),
            battery_percent: snapshot.power_of(device.id)&.battery_level,
            raw: device.raw)
        end
      end

      private

      def reachable?(device)
        connectivity = snapshot.connectivity_of(device.id)
        connectivity.nil? || connectivity.connected?
      end
    end
  end
end
