class House
  class RoomBuilder
    def initialize(group)
      @group = group
    end

    def build
      extension = @group.extension
      Room.new(
        id: @group.id, name: @group.name, kind: @group.kind, grouped_light_id: @group.grouped_light_id,
        lights: @group.lights.map { |light| LightBuilder.from_mirror(light) }.sort_by(&:name),
        scenes: recallable_scenes,
        custom_scenes: saved_custom_scenes,
        position: extension&.position, nickname: extension&.nickname, hidden: extension&.hidden
      )
    end

    private

    def saved_custom_scenes
      @group.custom_scenes.sort_by(&:created_at).map { |scene| CustomScene.new(id: scene.id, name: scene.name, light_ids: scene.lights.map(&:hue_light_id),
                       targets: scene_targets(scene.lights, :from_custom_scene_light)) }
    end

    def scene_targets(scene_lights, builder) = scene_lights.map { |scene_light| SceneTarget.public_send(builder, scene_light).to_h }

    def recallable_scenes
      Hue::Scene.arrange(@group.scenes.select(&:recallable?)).map { |scene| Scene.new(id: scene.id, name: scene.name, group_id: @group.id, light_ids: scene.actions.map(&:light_id), targets: scene_targets(scene.actions, :from_scene_action)) }
    end
  end
end
