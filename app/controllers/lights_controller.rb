class LightsController < ApplicationController
  include HueCalls

  COMMAND_FIELDS = %i[on brightness color x y mirek].freeze

  def panel = render_light_partial("lights/panel")

  def pin = render_light_partial("lights/pin")

  def update
    async_hue_call do
      light = Hue::Light.find(params[:id])
      HouseCommands::LightUpdate.new(light, params.require(:light).permit(*COMMAND_FIELDS))
    end
  end

  private

  def render_light_partial(partial)
    light = House.load(refresh: false).light(params[:id]) or raise ActiveRecord::RecordNotFound
    render partial:, locals: { light: }, layout: false
  end
end
