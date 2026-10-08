module Hue
  class Mirror
    class ConnectivityApplier < Applier
      PAYLOAD_CLASS = Api::Payloads::ZigbeeConnectivity

      def apply
        device = Device.find_by(id: payload.owner_id) or return
        return if device.reachable == payload.connected?

        device.update!(reachable: payload.connected?)
        changes.lights_changed(device.lights.pluck(:id))
      end
    end
  end
end
