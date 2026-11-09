class ButtonRule
  class Choices < Data.define(:rooms, :scenes_by_room)
    KINDS = [ Hue::Group::ROOM, Hue::Group::ZONE ].freeze

    def self.load
      rooms = Hue::Group.where(kind: KINDS).includes(:extension).sort_by(&:display_name)
      scenes = Hue::Scene.recallable.includes(:extension).group_by(&:group_id)
      new(
        rooms: rooms.map { |room| [ room.display_name, room.id ] },
        scenes_by_room: scenes.transform_values { |room_scenes| Hue::Scene.arrange(room_scenes).map { |scene| [ scene.display_name, scene.id ] } }
      )
    end

    def scenes_in(group_id) = scenes_by_room.fetch(group_id, [])
  end
end
