class DashboardController < ApplicationController
  # The everyday view: compact, no logs. Built for a phone.
  def show
    load_house
  end

  # The developer view: everything, plus the activity and press logs.
  def dev
    load_house(include_hidden: true)
    @activities = Activity.recent
    @presses = ControlEvent.includes(control: :device).recent.limit(8)
  end

  private

  def load_house(include_hidden: false)
    @house = House.load(include_hidden:)
    @state = Hue::ListenerState.current
  rescue Hue::Error => e
    @error = e.message
    render :unreachable, status: :service_unavailable
  end
end
