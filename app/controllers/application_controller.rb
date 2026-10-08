class ApplicationController < ActionController::Base
  include ToastStreams

  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from Hue::Error, with: :show_bridge_error
  before_action :require_bridge

  private

  def require_bridge
    redirect_to setup_path unless Hue.configured?
  end

  def show_bridge_error(error)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [ message_toast(error.message), turbo_stream.update(HouseBroadcast::Targets::EDITOR_ERROR, error.message) ], status: :unprocessable_entity
      end
      format.html { redirect_to root_path, alert: error.message }
    end
  end
end
