module Html
  class ApplicationController < ::ApplicationController
    allow_browser versions: :modern
    stale_when_importmap_changes

    before_action :require_bridge
    rescue_from Hue::Error, with: :show_unreachable

    private

    def require_bridge
      redirect_to setup_path unless Hue.configured?
    end

    def show_unreachable(error)
      @error = error.message
      render "html/dashboard/unreachable", status: :service_unavailable
    end
  end
end
