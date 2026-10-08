require "test_helper"
require "turbo/broadcastable/test_helper"

class Hue::ListenerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup { sync_mirror! }

  test "a batch is applied to the mirror, broadcast, and recorded as the last event" do
    batch = [ { "id" => "evt-9", "creationtime" => "2026-10-06T10:00:00Z", "type" => "update",
                "data" => [ { "type" => "light", "id" => "l2", "on" => { "on" => true } } ] } ]
    streams = capture_turbo_stream_broadcasts("house") { Hue::Listener.new(logger: Logger.new(nil)).handle(batch) }
    assert Hue::Light.find("l2").on
    assert_includes streams.map { _1["target"] }, "light_r1_l2"
    assert_equal "evt-9", Hue::ListenerState.current.last_event_id
  end

  test "the loop survives an unexpected error and stops when asked" do
    calls = 0
    stop = -> { calls >= 1 }
    Hue.client = Object.new.tap { |c| c.define_singleton_method(:devices) { calls += 1; raise NameError, "boom" } }
    Hue::Listener.new(stop:, logger: Logger.new(nil), sleeper: ->(_) {}).run
    assert_equal 1, calls
    refute Hue::ListenerState.current.live?
  end
end
