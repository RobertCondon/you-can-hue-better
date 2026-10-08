module HouseBroadcast
  module Targets
    HOUSE_SUMMARY = "house_summary"
    LISTENER_STATUS = "listener_status"
    RECENT_PRESSES = "recent_presses"
    FLASH = "flash"
    EDITOR_ERROR = "editor_error"
    LIGHT_DOCK = "light_dock"
    VISIBILITY = "visibility"

    module_function

    def house_summary = HOUSE_SUMMARY
    def listener_status = LISTENER_STATUS
    def recent_presses = RECENT_PRESSES
    def flash = FLASH
    def editor_error = EDITOR_ERROR
    def light_dock = LIGHT_DOCK
    def visibility = VISIBILITY

    def room(room) = "room_#{room.id}"
    def room_head(room) = "room_head_#{room.id}"
    def light_tile(room, light) = "light_#{room.id}_#{light.id}"
    def light_panel(light) = "light_panel_#{light.id}"
    def light_pin(light) = "light_pin_#{light.id}"
    def floor_lamp(light) = "floor_light_#{light.id}"
    def floor_net(net) = "floor_net_#{net.id}"
    def floor_item(item) = "floor_object_#{item.id}"
    def scene_card(scene) = "scene_card_#{scene.id}"
    def visibility_room(room) = "visibility_room_#{room.id}"
    def visibility_light(light) = "visibility_light_#{light.id}"
  end
end
