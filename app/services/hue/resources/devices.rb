module Hue
  module Resources
    class Devices < Resource
      RESOURCE_TYPE = ResourceType::DEVICE

      include Renamable
    end
  end
end
