module Hue
  module Resources
    class Scenes < Resource
      RESOURCE_TYPE = ResourceType::SCENE

      def recall(scene_id, action: SceneRecall::STATIC_LOOK) = command(scene_id, { recall: { action: } })
    end
  end
end
