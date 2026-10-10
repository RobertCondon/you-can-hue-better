class LightsController < ApiController
  include HueCalls

  COMMAND_FIELDS = %i[on brightness color x y mirek].freeze

  def update
    async_hue_call do
      light = Hue::Light.find(params[:id])
      HouseCommands::LightUpdate.new(light, params.require(:light).permit(*COMMAND_FIELDS))
    end
  end
end
