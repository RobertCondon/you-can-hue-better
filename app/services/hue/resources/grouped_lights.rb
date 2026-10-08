module Hue
  module Resources
    class GroupedLights < Resource
      RESOURCE_TYPE = ResourceType::GROUPED_LIGHT

      include Updatable
    end
  end
end
