module HueCalls
  TAB_HEADER = "X-Hue-Tab"

  private

  def async_hue_call
    reply = yield.call_later(tab: request.headers[TAB_HEADER])
    raise HouseCommands::LightsBusy, reply if reply.is_a?(HouseCommands::Busy)

    render json: { light_ids: reply.light_ids, check_in_ms: reply.check_in_milliseconds }, status: :accepted
  end

  def direct_hue_call
    result = yield.call_now
    raise HouseCommands::LightsBusy, result if result.is_a?(HouseCommands::Busy)

    result
  end
end
