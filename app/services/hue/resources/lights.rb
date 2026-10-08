module Hue
  module Resources
    class Lights < Resource
      RESOURCE_TYPE = ResourceType::LIGHT

      include Updatable
      include Renamable
    end
  end
end
