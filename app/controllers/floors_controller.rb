class FloorsController < ApplicationController
  def show
    @house = House.load(refresh: false)
    @floor = Floor.live(@house)
    @rooms = @house.rooms
    @scenes = Hue::Scene.by_room
  end

  def update
    place_light if params[:light_id].present?
    reshape_floor if params[:aspect].present?
    head :no_content
  end

  private

  def place_light = Floor::Placement.place!(group_id: Floor.home.id, light_id: params[:light_id], x: params[:x], y: params[:y])

  def reshape_floor = HueExtensions::Group.set_floor_aspect!(Floor.home.id, params[:aspect])
end
