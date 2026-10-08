# The house's floor: every light, where it sits, and what it looks like (live, or in a scene).
# One floor for the whole house, keyed by the bridge's "home" group; rooms and scenes are filters
# on it. Lights nobody has placed yet line up along the bottom so the floor works before any setup.
class Floor
  Spot = Data.define(:light, :x, :y, :placed, :muted, :room_ids)

  attr_reader :aspect, :spots, :objects, :nets

  def self.home = Hue::Group.find_by!(kind: "home")

  def self.live(house)
    new(house, house.lights.select { _1.on_floor? && !_1.hidden? })
  end

  # The house as a scene would set it: the scene's lights in their scene state, every other light greyed out.
  def self.for_scene(house, scene)
    by_light = scene.actions.index_by(&:light_id)
    lights = house.lights.select { _1.on_floor? && !_1.hidden? }.map { |l| by_light[l.id]&.to_snapshot || l }
    new(house, lights, muted: lights.map(&:id) - by_light.keys)
  end

  def initialize(house, lights, muted: [])
    @home = Floor.home
    @aspect = HueExtensions::Group.find_by(id: @home.id)&.floor_aspect&.to_f || 1.0
    @objects = FloorObject.where(group_id: @home.id).order(:id)
    @nets = FloorNet.includes(group: :extension).order(:id)
    rooms_of = Hash.new { |h, k| h[k] = [] }
    house.rooms.each { |r| r.lights.each { rooms_of[_1.id] << r.id } }
    placed = LightPlacement.map_for(@home.id)
    unplaced = lights.reject { placed.key?(_1.id) }
    @spots = lights.sort_by(&:display_name).map do |light|
      xy = placed[light.id]
      i = unplaced.index(light)
      Spot.new(light:, x: xy ? xy[0] : ((i + 0.5) / unplaced.size * 100).round(2), y: xy ? xy[1] : (i.even? ? 86.0 : 94.0),
               placed: xy.present?, muted: muted.include?(light.id), room_ids: rooms_of[light.id])
    end
  end

  def home_id = @home.id
  def unplaced_count = spots.count { !_1.placed }
end
