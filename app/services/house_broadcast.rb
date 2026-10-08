module HouseBroadcast
  STREAM = "house"
  RECENT_PRESS_COUNT = 8

  module_function

  def changes(changes) = ChangeBroadcast.new(changes).broadcast

  def everything
    house = House.load(refresh: false)
    house.rooms.each { |room| replace(Targets.room(room), "rooms/room", room:) }
    update(Targets::HOUSE_SUMMARY, "dashboard/summary", house:)
  end

  def listener_status
    update(Targets::LISTENER_STATUS, "dashboard/status", state: Hue::ListenerState.current)
  end

  def scene_cards(scene_ids)
    Hue::Scene.recallable.where(id: scene_ids.uniq).includes(:extension, :group, actions: { light: :extension }).each do |scene|
      replace(Targets.scene_card(scene), "scenes/card", scene:)
    end
  end

  def recent_presses
    update(Targets::RECENT_PRESSES, "dashboard/presses", presses: ControlEvent.includes(control: :device).recent.limit(RECENT_PRESS_COUNT))
  end

  def replace(target, partial, locals) = Turbo::StreamsChannel.broadcast_replace_to(STREAM, target:, partial:, locals:)

  def update(target, partial, locals) = Turbo::StreamsChannel.broadcast_update_to(STREAM, target:, partial:, locals:)
end
