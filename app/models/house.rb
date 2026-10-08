# Everything the dashboard needs, read from the hue_* mirror tables.
# House::Light / House::Room / House::Scene are the immutable snapshot objects it is built from.
class House
  attr_reader :rooms, :lights

  # When the listener isn't live the mirror can't be trusted, so refresh it from the bridge first.
  # If the bridge is unreachable but the mirror has data, render what we have; the dashboard shows
  # how old it is.
  # everything: true is /dev's view, with the rooms and lights marked hidden in the visibility list.
  # Everywhere else they are left out.
  def self.load(refresh: Hue::ListenerState.current.stale?, everything: false)
    if refresh
      begin
        Hue::Sync.run
      rescue Hue::Error
        raise if Hue::Light.none?
      end
    end
    new(Hue::Group.where(kind: %w[room zone]).includes(:scenes, :extension, lights: [ :extension, :device ]), Hue::Light.includes(:extension, :device), everything:)
  end

  def initialize(groups, lights, everything: false)
    @everything = everything
    @lights = lights.map(&:to_snapshot)
    @rooms = groups.map do |g|
      Room.new(
        id: g.id, name: g.name, kind: g.kind, grouped_light_id: g.grouped_light_id,
        lights: g.lights.map(&:to_snapshot).sort_by(&:name),
        scenes: g.scenes.select { _1.kind == "scene" }.map { Scene.new(id: _1.id, name: _1.name, group_id: g.id) }.sort_by(&:name),
        position: g.extension&.position, nickname: g.extension&.nickname, hidden: g.extension&.hidden
      )
    end
    unless everything
      @lights.reject!(&:hidden?)
      @rooms = @rooms.reject(&:hidden?).map { |r| r.with(lights: r.visible_lights) }
    end
    @rooms.sort_by! { |r| [ r.position ? 0 : 1, r.position || 0, -r.lights.size, -r.on_count, r.name ] }
  end

  def everything? = @everything

  def room(id)  = rooms.find { _1.id == id }
  def light(id) = lights.find { _1.id == id }
  def on_count  = lights.count { _1.lit? && !_1.hidden? }
end
