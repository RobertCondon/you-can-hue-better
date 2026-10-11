module RoomsHelper
  MIXED_CLASS = "is-mixed"

  def room_badges(room, badge_class: "room__kind")
    badges = []
    badges << t("rooms.badges.zone") if room.kind == Hue::Group::ZONE
    badges << t("rooms.badges.hidden") if room.hidden?
    safe_join(badges.map { |badge| tag.span(badge, class: badge_class) }.flat_map { |badge| [ " ", badge ] })
  end

  def room_power_target_state(room) = !room.any_on?

  def room_switch_label(room) = t("rooms.power.switch", room: room.display_name)
end
