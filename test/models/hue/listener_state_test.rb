require "test_helper"

class Hue::ListenerStateTest < ActiveSupport::TestCase
  test "live only with a recent heartbeat" do
    state = Hue::ListenerState.current
    assert state.stale?
    state.beat!(event_id: "x", event_at: Time.current)
    assert state.live?
    state.update_columns(heartbeat_at: 5.minutes.ago)
    assert state.stale?
    state.disconnected!
    assert_nil state.heartbeat_at
  end
end
