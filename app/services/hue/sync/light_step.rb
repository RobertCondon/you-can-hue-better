module Hue
  class Sync
    class LightStep < Step
      def run
        snapshot.lights.map do |light|
          upsert(Light, light.id, light.full_attributes.merge(device_id: light.owner_id, id_v1: light.legacy_id, raw: light.raw))
        end
      end
    end
  end
end
