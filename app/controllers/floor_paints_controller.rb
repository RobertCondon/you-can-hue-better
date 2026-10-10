class FloorPaintsController < ApiController
  include HueCalls

  def create
    async_hue_call { HouseCommands::Paint.new(params.require(:strokes)) }
  end
end
