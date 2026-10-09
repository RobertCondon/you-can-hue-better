module HouseBroadcast
  STREAM = "house"
  TAB_STREAM = "tab"
  SETTLE_ACTION = :settle
  LIGHT_IDS_ATTRIBUTE = "light-ids"
  RECENT_PRESS_COUNT = 8

  module_function

  def changes(changes) = ChangeBroadcast.new(changes).broadcast

  def everything
    house = House.load(refresh: false)
    send_streams([ *Streams.rooms(house), Streams.summary(house) ])
  end

  def listener_status = send_streams([ Streams.listener_status ])

  def settle(light_ids)
    Turbo::StreamsChannel.broadcast_action_to(STREAM, action: SETTLE_ACTION, attributes: { LIGHT_IDS_ATTRIBUTE => light_ids.join(" ") })
  end

  def toast_to_tab(tab, message)
    send_streams([ Streams.toast(message) ], to: tab_stream(tab)) if tab.present?
  end

  def tab_stream(tab) = [ TAB_STREAM, tab ]

  def send_streams(streams, to: STREAM)
    streams.each do |stream|
      Turbo::StreamsChannel.public_send(:"broadcast_#{stream.action}_to", to, target: stream.target, partial: stream.partial, locals: stream.locals)
    end
  end
end
