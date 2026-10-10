module ToastStreams
  DONE_TONE = "done"

  private

  def message_toast(message) = turbo_stream.update(HouseBroadcast::Targets::FLASH, partial: "shared/flash", locals: { message: })

  def cleared_toast = turbo_stream.update(HouseBroadcast::Targets::FLASH, "")
end
