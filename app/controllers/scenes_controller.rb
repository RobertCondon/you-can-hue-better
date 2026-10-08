class ScenesController < RoomsController
  # /scenes: every recallable scene, grouped by room in the dashboard's room order.
  def index
    @rooms = House.load(refresh: false).rooms
    scenes = Hue::Scene.recallable.includes(:extension, :group, actions: { light: :extension })
    @scenes_by_room = scenes.group_by(&:group_id).transform_values { |list| list.sort_by { |s| [ s.extension&.position || 1_000, s.display_name ] } }
  end

  # /scenes/:id: one scene and what each of its lights does.
  def show
    @scene = Hue::Scene.recallable.includes(:extension, :group, actions: { light: :extension }).find(params[:id])
    house  = House.load(refresh: false)
    @room  = house.room(@scene.group_id)
    @floor = Floor.for_scene(house, @scene)
    @lights = @scene.actions.map(&:to_snapshot).sort_by(&:display_name)
  end

  # What each light looks like in this scene, for previewing on a floor without touching the bulbs.
  def floor_state
    scene = Hue::Scene.recallable.includes(actions: { light: :device }).find(params[:id])
    render json: scene.actions.map { |a| s = a.to_snapshot; { light_id: a.light_id, on: s.lit?, hex: s.hex, bri: s.lit? ? (s.brightness / 100.0).round(2) : 0 } }
  end

  def activate = recall("active", "scene")
  def play     = recall("dynamic_palette", "play")

  private

  def recall(action, label)
    scene = Hue::Scene.recallable.find(params[:id])
    room  = scene.group
    undo  = UndoAction.capture("#{scene.display_name} #{label == "play" ? "played" : "set"} in #{room.display_name}", scene.actions.pluck(:light_id))

    response = Activity.record(target_kind: "scene", target_id: scene.id, target_name: "#{scene.name} in #{room.name}", action: label) do
      Hue.client.recall_scene(scene.id, action:)
    end

    settle
    render_rooms(notice: response["unreachable"] ? unreachable_message("A light in #{room.name}") : nil, scene_ids: [ scene.id ], undo:)
  end
end
