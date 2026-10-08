class LightNamesController < ApplicationController
  include HouseStreams

  NAME_FIELDS = %i[name nickname].freeze

  def update
    light = Hue::Light.find(params[:light_id])
    fields = params.require(:light).permit(*NAME_FIELDS)
    HouseCommands::RenameLight.call(light, fields[:name]) if fields.key?(:name)
    HueExtensions::Light.set_nickname!(light.id, fields[:nickname]) if fields.key?(:nickname)
    render_renamed(light)
  end

  private

  def render_renamed(light)
    house = House.load(refresh: false)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [ *turbo_streams_for(HouseBroadcast::Streams.room_changes(house, light_ids: [ light.id ])), turbo_stream.update(HouseBroadcast::Targets::EDITOR_ERROR, "") ]
      end
      format.html { redirect_to root_path }
    end
  end
end
