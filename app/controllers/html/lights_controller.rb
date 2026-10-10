module Html
  class LightsController < ApplicationController
    def panel = render_light_partial("lights/panel")

    def pin = render_light_partial("lights/pin")

    private

    def render_light_partial(partial)
      light = House.load(refresh: false).light(params[:id]) or raise ActiveRecord::RecordNotFound
      render partial:, locals: { light: }, layout: false
    end
  end
end
