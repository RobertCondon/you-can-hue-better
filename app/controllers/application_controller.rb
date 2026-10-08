class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from Hue::Error, with: :bridge_error
  before_action :require_bridge

  private

  # Until the app has a bridge key (environment, setup page, or config/hue.json) every page is the setup page.
  def require_bridge
    redirect_to setup_path unless Hue.configured?
  end

  # Rooms and scenes change several lights at once; the bridge needs a beat before it reports the new state.
  def settle = sleep(Rails.env.test? ? 0 : 0.3)

  # A stream that shows a message, or clears the previous one when message is nil.
  def flash_stream(message)
    message ? turbo_stream.update("flash", partial: "shared/flash", locals: { message: }) : turbo_stream.update("flash", "")
  end

  def unreachable_message(name) = "#{name} isn't responding. Check it has power at the switch."

  # The toast after a multi-light action: what happened, and Undo.
  def undo_stream(undo) = turbo_stream.update("flash", partial: "shared/undo", locals: { undo: })
  def done_stream(text) = turbo_stream.update("flash", partial: "shared/flash", locals: { message: text, tone: "done" })

  def bridge_error(error)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ flash_stream(error.message), turbo_stream.update("editor_error", error.message) ], status: :unprocessable_entity }
      format.html { redirect_to root_path, alert: error.message }
    end
  end
end
