module Html
  class ScenesController < ApplicationController
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
  end
end
