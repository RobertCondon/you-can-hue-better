class LightNamesController < ApplicationController
  include LightStreams

  NAME_FIELDS = %i[name nickname].freeze

  def update
    light = Hue::Light.find(params[:light_id])
    fields = params.require(:light).permit(*NAME_FIELDS)
    rename_on_bridge(light, fields[:name]) if fields.key?(:name)
    HueExtensions::Light.set_nickname!(light.id, fields[:nickname]) if fields.key?(:nickname)
    render_renamed(light)
  end

  private

  def rename_on_bridge(light, new_name)
    BridgeRename.new(light, activity_kind: LightsController::ACTIVITY_KIND).rename_to(new_name) do |name|
      Hue.client.lights.rename(light.id, name)
      Hue.client.devices.rename(light.device_id, name).tap { light.device.update!(name:) }
    end
  end

  def render_renamed(light)
    house = House.load(refresh: false)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ *light_tile_streams(house, house.light(light.id)), turbo_stream.update(HouseBroadcast::Targets::EDITOR_ERROR, "") ] }
      format.html { redirect_to root_path }
    end
  end
end
