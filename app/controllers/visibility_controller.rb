# The /dev visibility list: what the everyday views show. Hidden here is hidden everywhere outside /dev.
class VisibilityController < ApplicationController
  def light
    light = Hue::Light.find(params[:id])
    p = params.require(:light).permit(:hidden, :on_floor, :icon)
    HueExtensions::Light.set_visibility!(light.id, hidden: p[:hidden], on_floor: p[:on_floor], icon: p.key?(:icon) ? p[:icon] : :keep)
    HouseBroadcast.everything
    redirect_to dev_path(anchor: "visibility"), status: :see_other
  end

  def room
    group = Hue::Group.find(params[:id])
    HueExtensions::Group.set_hidden!(group.id, params.require(:room)[:hidden])
    HouseBroadcast.everything
    redirect_to dev_path(anchor: "visibility"), status: :see_other
  end
end
