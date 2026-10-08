class House
  module RoomOrder
    ARRANGED_FIRST = 0
    UNARRANGED_AFTER = 1
    NO_POSITION = 0

    module_function

    def sort(rooms) = rooms.sort_by { |room| sort_key(room) }

    def sort_key(room)
      [ room.position ? ARRANGED_FIRST : UNARRANGED_AFTER, room.position || NO_POSITION, -room.lights.size, -room.on_count, room.name ]
    end
  end
end
