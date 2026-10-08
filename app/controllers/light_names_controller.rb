# Name (on the bridge) and nickname (this dashboard only) for a light.
# The everyday view only sends a nickname; the dev view can send both.
class LightNamesController < ApplicationController
  def update
    light = Hue::Light.find(params[:light_id])
    p = params.require(:light).permit(:name, :nickname)

    if p.key?(:name) && (name = p[:name].to_s.strip) != light.name
      Activity.record(target_kind: "light", target_id: light.id, target_name: light.name, action: "rename to #{name}", payload: { name: }) do
        Hue.client.rename_light(light.id, name)
        Hue.client.rename_device(light.device_id, name)
      end
      light.update!(name:)
      light.device.update!(name:)
    end
    HueExtensions::Light.set_nickname!(light.id, p[:nickname]) if p.key?(:nickname)

    house = House.load(refresh: false)
    snapshot = house.light(light.id)
    respond_to do |format|
      format.turbo_stream do
        streams = house.rooms.select { |r| r.lights.include?(snapshot) }.map do |room|
          turbo_stream.replace("light_#{room.id}_#{light.id}", partial: "lights/light", locals: { light: snapshot, room: })
        end
        render turbo_stream: streams + [ turbo_stream.update("editor_error", "") ]
      end
      format.html { redirect_to root_path }
    end
  end
end
