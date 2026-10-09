require "test_helper"
require "turbo/broadcastable/test_helper"

class Hue::Mirror::ListenerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  SILENT_LOGGER = Logger.new(nil)
  NO_WAIT = ->(_seconds) { }

  setup { sync_mirror! }

  test "a batch is applied to the mirror, broadcast, and recorded as the last event" do
    batch = [ { "id" => "evt-9", "creationtime" => "2026-10-06T10:00:00Z", "type" => "update",
                "data" => [ { "type" => "light", "id" => "l2", "on" => { "on" => true } } ] } ]
    streams = capture_turbo_stream_broadcasts("house") { Hue::Mirror::Listener::BatchHandler.new(logger: SILENT_LOGGER).handle(batch) }
    assert Hue::Light.find("l2").on
    assert_includes streams.map { |stream| stream["target"] }, "light_r1_l2"
    assert_equal "evt-9", Hue::ListenerState.current.last_event_id
  end

  test "events for a light that is locked by a press are skipped, others still apply" do
    claim = Hue::Locks.claim(%w[l1])
    batch = [ { "id" => "evt-11", "creationtime" => "2026-10-06T10:00:00Z", "type" => "update",
                "data" => [ { "type" => "light", "id" => "l1", "on" => { "on" => false } }, { "type" => "light", "id" => "l2", "on" => { "on" => true } } ] } ]
    Hue::Mirror::Listener::BatchHandler.new(logger: SILENT_LOGGER).handle(batch)
    assert Hue::Light.find("l1").on
    assert Hue::Light.find("l2").on
  ensure
    Hue::Locks.release(claim)
  end

  test "a room's events are skipped while any of its lights is locked" do
    claim = Hue::Locks.claim(%w[l2])
    batch = [ { "id" => "evt-12", "creationtime" => "2026-10-06T10:00:00Z", "type" => "update",
                "data" => [ { "type" => "grouped_light", "id" => "g1", "dimming" => { "brightness" => 5.0 } },
                            { "type" => "grouped_light", "id" => "g2", "dimming" => { "brightness" => 5.0 } } ] } ]
    Hue::Mirror::Listener::BatchHandler.new(logger: SILENT_LOGGER).handle(batch)
    assert_equal [ 40.0, 5.0 ], [ Hue::Group.find("r1").brightness, Hue::Group.find("z1").brightness ]
  ensure
    Hue::Locks.release(claim)
  end

  test "a structural change in a batch triggers a full sync" do
    batch = [ { "id" => "evt-10", "creationtime" => "2026-10-06T10:00:00Z", "type" => "add", "data" => [ { "type" => "room", "id" => "r9" } ] } ]
    previous_sync = Hue::ListenerState.current.full_sync_at
    travel 1.minute do
      Hue::Mirror::Listener::BatchHandler.new(logger: SILENT_LOGGER).handle(batch)
    end
    assert_operator Hue::ListenerState.current.full_sync_at, :>, previous_sync
  end

  test "the loop survives an unexpected error and stops when asked" do
    attempts = 0
    failing_client = Object.new
    failing_client.define_singleton_method(:devices) { attempts += 1; raise NameError, "boom" }
    Hue.client = failing_client
    Hue::Mirror::Listener.new(stop: -> { attempts >= 1 }, logger: SILENT_LOGGER, sleeper: NO_WAIT).run
    assert_equal 1, attempts
    refute Hue::ListenerState.current.live?
  end

  test "the backoff doubles up to its ceiling and resets" do
    backoff = Hue::Mirror::Listener::Backoff.new
    seconds = 6.times.map { backoff.seconds.tap { backoff.increase } }
    assert_equal [ 1, 2, 4, 8, 16, 30 ], seconds
    backoff.reset
    assert_equal 1, backoff.seconds
  end
end
