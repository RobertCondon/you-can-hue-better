module HouseBroadcast
  class ChangeBroadcast
    def initialize(changes)
      @changes = changes
    end

    def broadcast
      HouseBroadcast.scene_cards(@changes.scene_ids) if @changes.scene_ids.any?
      return unless @changes.house_changed?

      broadcast_rooms
      HouseBroadcast.update(Targets::HOUSE_SUMMARY, "dashboard/summary", house:)
      broadcast_light_views
      HouseBroadcast.recent_presses if @changes.presses.any?
    end

    private

    def house = @house ||= House.load(refresh: false, include_hidden: true)

    def broadcast_rooms
      house.rooms.each do |room|
        changed_lights = room.lights.select { |light| @changes.light_ids.include?(light.id) }
        changed_lights.each { |light| HouseBroadcast.replace(Targets.light_tile(room, light), "lights/light", light:, room:) }
        HouseBroadcast.replace(Targets.room_head(room), "rooms/head", room:) if changed_lights.any? || @changes.group_ids.include?(room.id)
      end
    end

    def broadcast_light_views
      floor_spots = Floor.live(house).spots.index_by { |spot| spot.light.id }
      @changes.light_ids.uniq.filter_map { |light_id| house.light(light_id) }.each do |light|
        HouseBroadcast.replace(Targets.light_panel(light), "lights/panel", light:)
        HouseBroadcast.replace(Targets.light_pin(light), "lights/pin", light:)
        spot = floor_spots[light.id]
        HouseBroadcast.replace(Targets.floor_lamp(light), "floors/light", spot:) if spot
      end
    end
  end
end
