module HouseStreams
  private

  def turbo_streams_for(streams)
    streams.map { |stream| turbo_stream.public_send(stream.action, stream.target, partial: stream.partial, locals: stream.locals) }
  end
end
