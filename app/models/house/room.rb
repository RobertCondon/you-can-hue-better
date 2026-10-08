# A room or zone with its lights and scenes, as the bridge reports it right now.
# `position` is the saved dashboard position, or nil when the room has never been arranged.
class House::Room < Data.define(:id, :name, :kind, :grouped_light_id, :lights, :scenes, :position, :nickname, :hidden)
  def initialize(position: nil, nickname: nil, hidden: false, **rest) = super(position:, nickname: nickname.presence, hidden: !!hidden, **rest)

  def display_name = nickname || name
  def nicknamed?   = nickname.present?
  def hidden?      = hidden
  # Counts are of the lights the everyday view shows, so /dev and / agree on "3 of 4 on".
  def visible_lights = lights.reject(&:hidden?)
  def on_count = visible_lights.count(&:lit?)
  def any_on?  = on_count.positive?
  def all_on?  = visible_lights.all?(&:lit?)

  def summary
    return "All off" if on_count.zero?
    return "All on"  if all_on?
    "#{on_count} of #{visible_lights.size} on"
  end
end
