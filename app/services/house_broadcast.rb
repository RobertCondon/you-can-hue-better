# Pushes dashboard updates to every open page (they subscribe with turbo_stream_from "house").
module HouseBroadcast
  STREAM = "house"

  module_function

  def changes(changes)
    return unless changes.any?
    scenes(changes.scene_ids) if changes.scene_ids.any?
    return if changes.light_ids.empty? && changes.group_ids.empty? && changes.presses.empty?
    house = House.load(refresh: false, everything: true)
    house.rooms.each do |room|
      touched = false
      room.lights.each do |light|
        next unless changes.light_ids.include?(light.id)
        touched = true
        replace("light_#{room.id}_#{light.id}", "lights/light", light:, room:)
      end
      replace("room_head_#{room.id}", "rooms/head", room:) if touched || changes.group_ids.include?(room.id)
    end
    update("house_summary", "dashboard/summary", house:)
    floor = Floor.live(house)
    changes.light_ids.uniq.each do |id|
      light = house.light(id) or next
      replace("light_panel_#{id}", "lights/panel", light:)
      replace("light_pin_#{id}", "lights/pin", light:)
      spot = floor.spots.find { _1.light.id == id } and replace("floor_light_#{id}", "floors/light", spot:)
    end
    presses(changes.presses) if changes.presses.any?
  end

  def everything
    house = House.load(refresh: false)
    house.rooms.each { |room| replace("room_#{room.id}", "rooms/room", room:) }
    update("house_summary", "dashboard/summary", house:)
  end

  def status
    update("listener_status", "dashboard/status", state: Hue::ListenerState.current)
  end

  def scenes(ids)
    Hue::Scene.recallable.where(id: ids.uniq).includes(:extension, :group, actions: { light: :extension }).each do |scene|
      replace("scene_card_#{scene.id}", "scenes/card", scene:)
    end
  end

  def presses(_events)
    update("recent_presses", "dashboard/presses", presses: ControlEvent.includes(control: :device).recent.limit(8))
  end

  def replace(target, partial, locals) = Turbo::StreamsChannel.broadcast_replace_to(STREAM, target:, partial:, locals:)
  def update(target, partial, locals)  = Turbo::StreamsChannel.broadcast_update_to(STREAM, target:, partial:, locals:)
end
