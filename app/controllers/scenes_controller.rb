class ScenesController < ApplicationController
  include HueCalls

  def index
    @rooms = House.load(refresh: false).rooms
    @scenes_by_room = Hue::Scene.by_room
  end

  def show
    @scene = Hue::Scene.for_cards.find(params[:id])
    house = House.load(refresh: false)
    @room = house.room(@scene.group_id)
    @floor = Floor.for_scene(house, @scene)
    @lights = @scene.actions.map { |action| House::LightBuilder.from_scene_action(action) }.sort_by(&:display_name)
  end

  def floor_state
    render json: Floor::ScenePreview.light_states(Hue::Scene.for_cards.find(params[:id]))
  end

  def activate = recall(Hue::Api::SceneRecall::STATIC_LOOK)

  def play = recall(Hue::Api::SceneRecall::PLAY_PALETTE)

  private

  def recall(mode)
    async_hue_call { HouseCommands::SceneRecall.new(Hue::Scene.recallable.find(params[:id]), mode) }
  end
end
