module Html
  class DashboardController < ApplicationController
    rescue_from Hue::Error, with: :show_unreachable

    def show
      load_house
    end

    def dev
      load_house(include_hidden: true)
      @activities = Activity.recent
      @presses = ControlEvent.includes(control: :device).recent.limit(HouseBroadcast::RECENT_PRESS_COUNT)
    end

    private

    def load_house(include_hidden: false)
      @house = House.load(include_hidden:)
      @state = Hue::ListenerState.current
    end

    def show_unreachable(error)
      @error = error.message
      render :unreachable, status: :service_unavailable
    end
  end
end
