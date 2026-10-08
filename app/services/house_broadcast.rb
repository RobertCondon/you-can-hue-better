module HouseBroadcast
  STREAM = "house"
  RECENT_PRESS_COUNT = 8

  module_function

  def changes(changes) = ChangeBroadcast.new(changes).broadcast

  def everything
    house = House.load(refresh: false)
    send_streams([ *Streams.rooms(house), Streams.summary(house) ])
  end

  def listener_status = send_streams([ Streams.listener_status ])

  def send_streams(streams)
    streams.each do |stream|
      Turbo::StreamsChannel.public_send(:"broadcast_#{stream.action}_to", STREAM, target: stream.target, partial: stream.partial, locals: stream.locals)
    end
  end
end
