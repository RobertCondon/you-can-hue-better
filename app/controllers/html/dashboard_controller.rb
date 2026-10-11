module Html
  class DashboardController < ApplicationController
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
  end
end
