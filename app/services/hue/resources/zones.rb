module Hue
  module Resources
    class Zones < Resource
      RESOURCE_TYPE = ResourceType::ZONE

      include Renamable
    end
  end
end
