class FloorPaintsController < ApplicationController
  include HouseStreams

  def create
    paint = HouseCommands::Paint.new(params.require(:strokes))
    result = paint.call_now
    house = House.load(refresh: false)
    streams = [ *HouseBroadcast::Streams.floor_lamps(house, paint.painted_light_ids), HouseBroadcast::Streams.summary(house) ]
    render turbo_stream: [ *turbo_streams_for(streams), result_toast(result, t(".a_painted_light")) ]
  end
end
