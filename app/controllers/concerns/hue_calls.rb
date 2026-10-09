module HueCalls
  extend ActiveSupport::Concern
  include HouseStreams

  TAB_HEADER = "X-Hue-Tab"
  CHECK_IN_HEADER = "Check-In-After"

  included do
    rescue_from HouseCommands::LightsBusy, with: :reply_busy
  end

  private

  def async_hue_call
    reply = yield.call_later(tab: request.headers[TAB_HEADER])
    raise HouseCommands::LightsBusy, reply if reply.is_a?(HouseCommands::Busy)

    response.set_header(CHECK_IN_HEADER, reply.check_in_milliseconds.to_s)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: cleared_toast, status: :accepted }
      format.html { redirect_back_or_to root_path, status: :see_other }
    end
  end

  def direct_hue_call
    result = yield.call_now
    raise HouseCommands::LightsBusy, result if result.is_a?(HouseCommands::Busy)

    result
  end

  def reply_busy(error)
    busy = error.busy
    message = Toasts.lights_busy(busy.target_name)
    respond_to do |format|
      format.turbo_stream do
        streams = HouseBroadcast::Streams.lights_everywhere(House.load(refresh: false), busy.light_ids)
        render turbo_stream: [ *turbo_streams_for(streams), message_toast(message) ], status: :conflict
      end
      format.html { redirect_back_or_to root_path, alert: message, status: :see_other }
    end
  end
end
