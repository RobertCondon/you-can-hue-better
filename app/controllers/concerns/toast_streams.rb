module ToastStreams
  DONE_TONE = "done"

  private

  def message_toast(message) = turbo_stream.update(HouseBroadcast::Targets::FLASH, partial: "shared/flash", locals: { message: })

  def cleared_toast = turbo_stream.update(HouseBroadcast::Targets::FLASH, "")

  def unreachable_message(light_description) = t("toasts.not_responding", light: light_description)

  def result_toast(result, light_description)
    result.unreachable_lights? ? message_toast(unreachable_message(light_description)) : cleared_toast
  end
end
