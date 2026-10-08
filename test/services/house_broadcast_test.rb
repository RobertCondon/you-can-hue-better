require "test_helper"
require "turbo/broadcastable/test_helper"

class HouseBroadcastTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup { sync_mirror! }

  test "a light change replaces its tiles in every section, the room heads and the summary" do
    changes = Hue::Mirror::Changes.new([ "l1" ], [], [], [], false)
    streams = capture_turbo_stream_broadcasts("house") { HouseBroadcast.changes(changes) }
    targets = streams.map { _1["target"] }
    assert_includes targets, "light_r1_l1"
    assert_includes targets, "light_z1_l1"
    assert_includes targets, "room_head_r1"
    assert_includes targets, "room_head_z1"
    assert_includes targets, "house_summary"
    refute_includes targets, "light_r1_l2"
    assert_includes targets, "light_panel_l1", "an open panel for the light refreshes too"
  end

  test "a scene change replaces its card" do
    changes = Hue::Mirror::Changes.new([], [], [], [ "s1" ], false)
    streams = capture_turbo_stream_broadcasts("house") { HouseBroadcast.changes(changes) }
    assert_equal [ "scene_card_s1" ], streams.map { _1["target"] }
  end

  test "nothing is broadcast for no changes" do
    assert_no_turbo_stream_broadcasts("house") { HouseBroadcast.changes(Hue::Mirror::Changes.none) }
  end
end
