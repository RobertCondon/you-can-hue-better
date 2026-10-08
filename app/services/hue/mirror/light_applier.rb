module Hue
  class Mirror
    class LightApplier < Applier
      PAYLOAD_CLASS = Api::Payloads::Light

      def apply
        light = Light.find_by(id: payload.id) or return changes.full_sync_needed!
        light.assign_attributes(payload.reported_attributes)
        return unless light.changed?

        light.raw = light.raw.deep_merge(payload.raw)
        light.save!
        changes.lights_changed(light.id)
      end
    end
  end
end
