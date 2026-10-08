module HouseBroadcast
  class ChangeBroadcast
    def initialize(changes)
      @changes = changes
    end

    def broadcast
      streams = @changes.scene_ids.any? ? Streams.scene_cards(@changes.scene_ids) : []
      streams += house_streams if @changes.house_changed?
      HouseBroadcast.send_streams(streams)
    end

    private

    def house = @house ||= House.load(refresh: false, include_hidden: true)

    def house_streams
      light_ids = @changes.light_ids.uniq
      [
        *Streams.room_changes(house, light_ids:, group_ids: @changes.group_ids),
        Streams.summary(house),
        *light_ids.filter_map { |light_id| house.light(light_id) }.flat_map { |light| Streams.light_details(light) },
        *Streams.floor_lamps(house, light_ids),
        *(Streams.recent_presses if @changes.presses.any?)
      ]
    end
  end
end
