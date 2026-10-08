class LightsController < ApplicationController
  include LightStreams

  COMMAND_FIELDS = %i[on brightness color x y mirek].freeze
  ACTIVITY_KIND = "light"

  def panel = render_light_partial("lights/panel")

  def pin = render_light_partial("lights/pin")

  def update
    light = Hue::Light.find(params[:id])
    command = LightCommand.new(light, params.require(:light).permit(*COMMAND_FIELDS)).command
    result = ActivityRecorder.record(target_kind: ACTIVITY_KIND, target_id: light.id, target_name: light.name, action: command.description, payload: command.changes) do
      Hue.client.lights.update(light.id, command.changes)
    end
    HouseBroadcast.changes(Hue::Mirror.apply([ Hue.client.lights.find(light.id) ]))
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
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          *light_tile_streams(house, snapshot), *room_head_streams(house, snapshot), *light_detail_streams(snapshot),
          turbo_stream.update(HouseBroadcast::Targets::HOUSE_SUMMARY, partial: "dashboard/summary", locals: { house: }),
          warning ? message_toast(warning) : cleared_toast
        ]
      end
      format.html { redirect_to root_path, alert: warning }
    end
  end
end
