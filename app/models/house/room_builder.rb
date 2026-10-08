class House
  class RoomBuilder
    def initialize(group)
      @group = group
    end

    def build
      extension = @group.extension
      Room.new(
        id: @group.id, name: @group.name, kind: @group.kind, grouped_light_id: @group.grouped_light_id,
        lights: @group.lights.map(&:to_snapshot).sort_by(&:name),
        scenes: recallable_scenes,
        position: extension&.position, nickname: extension&.nickname, hidden: extension&.hidden
      )
    end

    private

    def recallable_scenes
      @group.scenes.select { |scene| scene.kind == Hue::Scene::SCENE }
            .map { |scene| Scene.new(id: scene.id, name: scene.name, group_id: @group.id) }
            .sort_by(&:name)
    end
  end
end
