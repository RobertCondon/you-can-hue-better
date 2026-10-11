module HouseBroadcast
  module Streams
    REPLACE = :replace
    UPDATE = :update

    Stream = Data.define(:action, :target, :partial, :locals)

    module_function

    def rooms(house) = house.rooms.flat_map { |room| room(room) }

    def room(room) = [ *room_summary(room), replace(Targets.room_body(room), "rooms/body", room:) ]

    def room_summary(room)
      [ replace(Targets.room_card(room), "rooms/card", room:), replace(Targets.room_tab(room), "rooms/tab", room:), replace(Targets.room_row(room), "rooms/row", room:) ]
    end

    def room_changes(house, light_ids:, group_ids: [])
      house.rooms.flat_map do |room|
        changed_lights = room.lights.select { |light| light_ids.include?(light.id) }
        tiles = changed_lights.map { |light| replace(Targets.light_tile(room, light), "lights/light", light:, room:) }
        changed_lights.any? || group_ids.include?(room.id) ? [ *tiles, *room_summary(room) ] : tiles
      end
    end

    def light_details(light)
      [
        replace(Targets.light_panel(light), "lights/panel", light:),
        replace(Targets.light_pin(light), "lights/pin", light:),
        replace(Targets.light_sheet(light), "lights/sheet", light:)
      ]
    end

    def floor_lamps(house, light_ids)
      Floor.live(house).spots.select { |spot| light_ids.include?(spot.light.id) }
           .map { |spot| replace(Targets.floor_lamp(spot.light), "floors/light", spot:) }
    end

    def lights_everywhere(house, light_ids, group_ids: [])
      [
        *room_changes(house, light_ids:, group_ids:),
        *light_ids.filter_map { |light_id| house.light(light_id) }.flat_map { |light| light_details(light) },
        *floor_lamps(house, light_ids)
      ]
    end

    def summary(house) = update(Targets::HOUSE_SUMMARY, "dashboard/summary", house:)

    def toast(message) = update(Targets::FLASH, "shared/flash", message:)

    def scene_cards(scene_ids)
      Hue::Scene.for_cards.where(id: scene_ids.uniq).map { |scene| replace(Targets.scene_card(scene), "scenes/card", scene:) }
    end

    def listener_status = update(Targets::LISTENER_STATUS, "dashboard/status", state: Hue::ListenerState.current)

    def recent_presses
      update(Targets::RECENT_PRESSES, "dashboard/presses", presses: ControlEvent.includes(control: :device).recent.limit(RECENT_PRESS_COUNT))
    end

    def replace(target, partial, locals) = Stream.new(action: REPLACE, target:, partial:, locals:)

    def update(target, partial, locals) = Stream.new(action: UPDATE, target:, partial:, locals:)
  end
end
