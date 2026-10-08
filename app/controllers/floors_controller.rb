# The house drawn as a floor: a dot per light with its glow, walls that shape the light, furniture.
class FloorsController < ApplicationController
  def show
    @house  = House.load(refresh: false)
    @floor  = Floor.live(@house)
    @rooms  = @house.rooms
    @scenes = Hue::Scene.recallable.includes(:extension, group: :extension).sort_by(&:display_name).group_by(&:group_id)
  end

  # Edit floor: a dropped light, or the floor's shape.
  def update
    home = Floor.home
    if params[:light_id].present?
      LightPlacement.place!(group_id: home.id, light_id: params[:light_id], x: params[:x], y: params[:y])
    end
    if params[:aspect].present?
      HueExtensions::Group.find_or_initialize_by(id: home.id).update!(floor_aspect: params[:aspect].to_f.clamp(0.4, 2.5))
    end
    head :no_content
  end
end
