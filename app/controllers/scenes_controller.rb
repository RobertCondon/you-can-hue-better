class ScenesController < ApplicationController
  include HouseSectionStreams

  def index
    @rooms = House.load(refresh: false).rooms
    @scenes_by_room = ScenesByRoom.call
  end

  def show
    @scene = Hue::Scene.recallable.includes(:extension, :group, actions: { light: :extension }).find(params[:id])
    house = House.load(refresh: false)
    @room = house.room(@scene.group_id)
    @floor = Floor.for_scene(house, @scene)
    @lights = @scene.actions.map(&:to_snapshot).sort_by(&:display_name)
  end

  def floor_state
    render json: ScenePreview.light_states(Hue::Scene.recallable.includes(actions: { light: :device }).find(params[:id]))
  end

  def activate = recall(Hue::SceneRecall::STATIC_LOOK)

  def play = recall(Hue::SceneRecall::PLAY_PALETTE)

  private

  def recall(mode)
    scene = Hue::Scene.recallable.find(params[:id])
    outcome = HouseCommands::SceneRecall.new(scene, mode).run
    wait_for_bridge_to_settle
    render_house_sections(toast: outcome_toast(outcome, t("rooms.update.a_light_in", room: scene.group.name)), scene_ids: [ scene.id ])
  end
end
