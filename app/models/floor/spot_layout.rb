class Floor
  class SpotLayout
    WAITING_ROW_HEIGHTS = [ 86.0, 94.0 ].freeze
    SLOT_CENTRE = 0.5
    FULL_WIDTH = 100

    def initialize(house:, lights:, home_id:, muted_light_ids:)
      @house = house
      @lights = lights
      @home_id = home_id
      @muted_light_ids = muted_light_ids
    end

    def spots = @lights.sort_by(&:display_name).map { |light| spot_for(light) }

    private

    def spot_for(light)
      spot_x, spot_y = placements[light.id] || waiting_position(light)
      Spot.new(light:, x: spot_x, y: spot_y, placed: placements.key?(light.id), muted: @muted_light_ids.include?(light.id), room_ids: room_ids_by_light.fetch(light.id, []))
    end

    def waiting_position(light)
      slot = waiting_lights.index(light)
      waiting_x = ((slot + SLOT_CENTRE) / waiting_lights.size * FULL_WIDTH).round(FloorCoordinates::DECIMAL_PLACES)
      [ waiting_x, WAITING_ROW_HEIGHTS[slot % WAITING_ROW_HEIGHTS.size] ]
    end

    def placements = @placements ||= LightPlacement.positions_on(@home_id)

    def waiting_lights = @waiting_lights ||= @lights.reject { |light| placements.key?(light.id) }

    def room_ids_by_light
      @room_ids_by_light ||= @house.rooms.each_with_object(Hash.new { |by_light, light_id| by_light[light_id] = [] }) do |room, by_light|
        room.lights.each { |light| by_light[light.id] << room.id }
      end
    end
  end
end
