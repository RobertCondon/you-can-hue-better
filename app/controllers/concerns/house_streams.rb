module HouseStreams
  private

  def turbo_streams_for(streams)
    streams.map { |stream| turbo_stream.public_send(stream.action, stream.target, partial: stream.partial, locals: stream.locals) }
  end

  def render_house_sections(toast:, scene_ids: [])
    house = House.load(refresh: false)
    streams = [ *HouseBroadcast::Streams.rooms(house), *HouseBroadcast::Streams.scene_cards(scene_ids), HouseBroadcast::Streams.summary(house) ]
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ *turbo_streams_for(streams), toast ] }
      format.html { redirect_back_or_to root_path }
    end
  end
end
