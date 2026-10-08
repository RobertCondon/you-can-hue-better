module Hue
  class Mirror
    TYPE_FIELD = "type"
    APPLIERS = {
      ResourceType::LIGHT => LightApplier,
      ResourceType::GROUPED_LIGHT => GroupedLightApplier,
      ResourceType::BUTTON => ButtonApplier,
      ResourceType::RELATIVE_ROTARY => RotaryApplier,
      ResourceType::ZIGBEE_CONNECTIVITY => ConnectivityApplier,
      ResourceType::DEVICE_POWER => PowerApplier,
      ResourceType::SCENE => SceneApplier
    }.freeze
    STRUCTURAL_TYPES = [ ResourceType::DEVICE, ResourceType::ROOM, ResourceType::ZONE, ResourceType::SMART_SCENE ].freeze

    def self.apply(resources, event: Event.local, changes: Changes.new)
      resources.each { |resource| apply_resource(resource, event:, changes:) }
      changes
    end

    def self.refresh(client = Hue.client)
      apply(client.lights.all + client.grouped_lights.all)
    end

    def self.apply_resource(resource, event:, changes:)
      resource_type = resource[TYPE_FIELD]
      return changes.full_sync_needed! if STRUCTURAL_TYPES.include?(resource_type)

      APPLIERS[resource_type]&.new(resource, event:, changes:)&.apply
    end
  end
end
