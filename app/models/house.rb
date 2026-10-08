class House
  attr_reader :rooms, :lights

  def self.load(refresh: Hue::ListenerState.current.stale?, include_hidden: false)
    Loader.new(refresh:, include_hidden:).load
  end

  def initialize(rooms:, lights:)
    @rooms = rooms
    @lights = lights
  end

  def room(room_id) = rooms.find { |room| room.id == room_id }
  def light(light_id) = lights.find { |light| light.id == light_id }
  def on_count = lights.count { |light| light.lit? && !light.hidden? }
end
