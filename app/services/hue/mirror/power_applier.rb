module Hue
  class Mirror
    class PowerApplier < Applier
      PAYLOAD_CLASS = Payloads::DevicePower

      def apply
        device = Device.find_by(id: payload.owner_id) or return
        battery_level = payload.battery_level or return
        device.update!(battery_percent: battery_level) unless device.battery_percent == battery_level
      end
    end
  end
end
