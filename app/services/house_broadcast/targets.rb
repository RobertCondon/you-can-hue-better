module HouseBroadcast
  module Targets
    HOUSE_SUMMARY = "house_summary"
    LISTENER_STATUS = "listener_status"
    RECENT_PRESSES = "recent_presses"
    FLASH = "flash"
    EDITOR_ERROR = "editor_error"

    module_function

    def room(room) = "room_#{room.id}"
    def room_head(room) = "room_head_#{room.id}"
    def light_tile(room, light) = "light_#{room.id}_#{light.id}"
    def light_panel(light) = "light_panel_#{light.id}"
    def light_pin(light) = "light_pin_#{light.id}"
    def floor_lamp(light) = "floor_light_#{light.id}"
    def scene_card(scene) = "scene_card_#{scene.id}"
  end
end
