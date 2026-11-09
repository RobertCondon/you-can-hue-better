module ButtonRules
  # The rooms, lights and scenes a rule's menus offer, loaded once per page or broadcast.
  class Choices < Data.define(:rooms, :lights, :scenes_by_room)
    ROOM_KINDS = [ Hue::Group::ROOM, Hue::Group::ZONE ].freeze

    def self.call
      rooms = Hue::Group.where(kind: ROOM_KINDS).includes(:extension).sort_by(&:display_name)
      lights = Hue::Light.includes(:extension).map { |light| [ light.extension&.nickname.presence || light.name, light.id ] }.sort
      scenes = Hue::Scene.recallable.includes(:extension).group_by(&:group_id)
      new(
        rooms: rooms.map { |room| [ room.display_name, SubjectKey.dump(ButtonRule::ROOM, room.id) ] },
        lights: lights.map { |name, id| [ name, SubjectKey.dump(ButtonRule::LIGHT, id) ] },
        scenes_by_room: scenes.transform_values { |room_scenes| Hue::Scene.arrange(room_scenes).map { |scene| [ scene.display_name, scene.id ] } }
      )
    end

    # Rooms and lights, grouped, for a menu; a scene can only be set in a room.
    def subjects(rooms_only: false)
      grouped = { I18n.t("button_rules.choices.rooms") => rooms }
      rooms_only ? grouped : grouped.merge(I18n.t("button_rules.choices.lights") => lights)
    end

    def scenes_in(group_id) = scenes_by_room.fetch(group_id, [])
  end
end
