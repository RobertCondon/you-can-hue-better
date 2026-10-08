module LightStreams
  private

  def light_tile_streams(house, light)
    rooms_containing(house, light).map do |room|
      turbo_stream.replace(HouseBroadcast::Targets.light_tile(room, light), partial: "lights/light", locals: { light:, room: })
    end
  end

  def room_head_streams(house, light)
    rooms_containing(house, light).map { |room| turbo_stream.replace(HouseBroadcast::Targets.room_head(room), partial: "rooms/head", locals: { room: }) }
  end

  def light_detail_streams(light)
    [ turbo_stream.replace(HouseBroadcast::Targets.light_panel(light), partial: "lights/panel", locals: { light: }),
      turbo_stream.replace(HouseBroadcast::Targets.light_pin(light), partial: "lights/pin", locals: { light: }) ]
  end

  def rooms_containing(house, light) = house.rooms.select { |room| room.lights.include?(light) }
end
