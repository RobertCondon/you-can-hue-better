class House
  class Loader
    ROOM_KINDS = [ Hue::Group::ROOM, Hue::Group::ZONE ].freeze

    def initialize(refresh:, include_hidden:)
      @refresh = refresh
      @include_hidden = include_hidden
    end

    def load
      refresh_mirror if @refresh
      rooms = mirror_groups.map { |group| RoomBuilder.new(group).build }
      lights = mirror_lights.map { |light| LightBuilder.from_mirror(light) }
      rooms, lights = without_hidden(rooms, lights) unless @include_hidden
      House.new(rooms: RoomOrder.sort(rooms), lights:)
    end

    private

    def refresh_mirror
      Hue::Mirror::Sync.call
    rescue Hue::Error
      raise if Hue::Light.none?
    end

    def mirror_groups = Hue::Group.where(kind: ROOM_KINDS).includes(:extension, scenes: [ :extension, :actions ], lights: [ :extension, :device ])

    def mirror_lights = Hue::Light.includes(:extension, :device)

    def without_hidden(rooms, lights)
      visible_rooms = rooms.reject(&:hidden?).map { |room| room.with(lights: room.visible_lights) }
      [ visible_rooms, lights.reject(&:hidden?) ]
    end
  end
end
