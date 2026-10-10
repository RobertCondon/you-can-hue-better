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
        position: extension&.position, nickname: extension&.nickname, hidden: extension&.hidden
      )
    end

    private

    def recallable_scenes
      Hue::Scene.arrange(@group.scenes.select(&:recallable?)).map { |scene| Scene.new(id: scene.id, name: scene.name, group_id: @group.id, light_ids: scene.actions.map(&:light_id)) }
    end
  end
end
