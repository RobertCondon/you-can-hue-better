class LightsController < ApplicationController
  include HouseStreams

  COMMAND_FIELDS = %i[on brightness color x y mirek].freeze

  def panel = render_light_partial("lights/panel")

  def pin = render_light_partial("lights/pin")

  def update
    light = Hue::Light.find(params[:id])
    result = HouseCommands::LightUpdate.call(light, params.require(:light).permit(*COMMAND_FIELDS))
    render_light_update(light, warning: (unreachable_message(light.name) if result.unreachable_lights?))
  end

  private

  def render_light_partial(partial)
    light = House.load(refresh: false).light(params[:id]) or raise ActiveRecord::RecordNotFound
    render partial:, locals: { light: }, layout: false
  end

  def render_light_update(light, warning:)
    house = House.load(refresh: false)
    snapshot = house.light(light.id)
    streams = [ *HouseBroadcast::Streams.room_changes(house, light_ids: [ light.id ]), *HouseBroadcast::Streams.light_details(snapshot), HouseBroadcast::Streams.summary(house) ]
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ *turbo_streams_for(streams), warning ? message_toast(warning) : cleared_toast ] }
      format.html { redirect_to root_path, alert: warning }
    end
  end
end
