module Html
  class FloorsController < ApplicationController
    def show
      @house = House.load(refresh: false)
      @floor = Floor.live(@house)
      @rooms = @house.rooms
      @scenes = Hue::Scene.by_room
    end
  end
end
