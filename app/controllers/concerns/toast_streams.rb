module ToastStreams
  DONE_TONE = "done"

  private

  def message_toast(message) = turbo_stream.update(HouseBroadcast::Targets::FLASH, partial: "shared/flash", locals: { message: })

  def done_toast(message) = turbo_stream.update(HouseBroadcast::Targets::FLASH, partial: "shared/flash", locals: { message:, tone: DONE_TONE })

  def undo_toast(undo) = turbo_stream.update(HouseBroadcast::Targets::FLASH, partial: "shared/undo", locals: { undo: })

  def cleared_toast = turbo_stream.update(HouseBroadcast::Targets::FLASH, "")

  def unreachable_message(light_description) = t("toasts.not_responding", light: light_description)

  def outcome_toast(outcome, light_description)
    outcome.unreachable_lights? ? message_toast(unreachable_message(light_description)) : undo_toast(outcome.undo)
  end
end
