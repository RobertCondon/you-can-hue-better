class VisibilityController < ApiController
  LIGHT_SETTINGS = %i[hidden on_floor icon].freeze

  def light
    light = Hue::Light.find(params[:id])
    HueExtensions::Light.set_visibility!(light.id, params.require(:light).permit(*LIGHT_SETTINGS))
    show_everywhere
  end

  def room
    group = Hue::Group.find(params[:id])
    HueExtensions::Group.set_hidden!(group.id, params.require(:room)[:hidden])
    show_everywhere
  end

  private

  def show_everywhere
    HouseBroadcast.everything
    head :no_content
  end
end
