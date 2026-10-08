module Hue
  module Resources
    class Rooms < Resource
      RESOURCE_TYPE = ResourceType::ROOM

      include Renamable
    end
  end
end
