module Hue
  class Mirror
    TYPE_FIELD = "type"
    APPLIERS = {
      Api::ResourceType::LIGHT => LightApplier,
      Api::ResourceType::GROUPED_LIGHT => GroupedLightApplier,
      Api::ResourceType::BUTTON => ButtonApplier,
      Api::ResourceType::RELATIVE_ROTARY => RotaryApplier,
      Api::ResourceType::ZIGBEE_CONNECTIVITY => ConnectivityApplier,
      Api::ResourceType::DEVICE_POWER => PowerApplier,
      Api::ResourceType::SCENE => SceneApplier
    }.freeze
    STRUCTURAL_TYPES = [ Api::ResourceType::DEVICE, Api::ResourceType::ROOM, Api::ResourceType::ZONE, Api::ResourceType::SMART_SCENE ].freeze

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
