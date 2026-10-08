class Floor
  DEFAULT_ASPECT = 1.0

  Spot = Data.define(:light, :x, :y, :placed, :muted, :room_ids)

  attr_reader :aspect, :spots, :items, :nets

  def self.home = Hue::Group.find_by!(kind: Hue::Group::HOME)

  def self.live(house) = new(house, drawable_lights(house))

  def self.for_scene(house, scene)
    actions_by_light = scene.actions.index_by(&:light_id)
    lights = drawable_lights(house).map { |light| (action = actions_by_light[light.id]) ? House::LightBuilder.from_scene_action(action) : light }
    new(house, lights, muted_light_ids: lights.map(&:id) - actions_by_light.keys)
  end

  def self.drawable_lights(house) = house.lights.select { |light| light.on_floor? && !light.hidden? }

  def initialize(house, lights, muted_light_ids: [])
    @home = self.class.home
    @aspect = HueExtensions::Group.find_by(id: @home.id)&.floor_aspect&.to_f || DEFAULT_ASPECT
    @items = Item.where(group_id: @home.id).order(:id)
    @nets = Net.includes(group: :extension).order(:id)
    @spots = SpotLayout.new(house:, lights:, home_id: @home.id, muted_light_ids:).spots
  end

  def home_id = @home.id
  def unplaced_count = spots.count { |spot| !spot.placed }
  def outline = nets.outlines.first
end
