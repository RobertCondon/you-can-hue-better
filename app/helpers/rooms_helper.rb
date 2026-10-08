module RoomsHelper
  def room_badges(room, badge_class: "room__kind")
    badges = []
    badges << t("rooms.badges.zone") if room.kind == Hue::Group::ZONE
    badges << t("rooms.badges.hidden") if room.hidden?
    safe_join(badges.map { |badge| tag.span(badge, class: badge_class) }.flat_map { |badge| [ " ", badge ] })
  end

  def room_power_target_state(room) = !room.any_on?

  def room_power_label(room) = t(room.any_on? ? "rooms.power.turn_off" : "rooms.power.turn_on", room: room.display_name)

  def room_power_title(room) = t(room.any_on? ? "rooms.power.title_off" : "rooms.power.title_on")
end
