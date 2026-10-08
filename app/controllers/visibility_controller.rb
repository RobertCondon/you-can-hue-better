class VisibilityController < ApplicationController
  LIGHT_SETTINGS = %i[hidden on_floor icon].freeze
  VISIBILITY_ANCHOR = "visibility"

  def light
    light = Hue::Light.find(params[:id])
    HueExtensions::Light.set_visibility!(light.id, params.require(:light).permit(*LIGHT_SETTINGS))
    refresh_and_return
  end

  def room
    group = Hue::Group.find(params[:id])
    HueExtensions::Group.set_hidden!(group.id, params.require(:room)[:hidden])
    refresh_and_return
  end

  private

  def refresh_and_return
    HouseBroadcast.everything
    redirect_to dev_path(anchor: VISIBILITY_ANCHOR), status: :see_other
  end
end
