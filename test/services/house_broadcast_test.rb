require "test_helper"
require "turbo/broadcastable/test_helper"

class HouseBroadcastTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup { sync_mirror! }

  def broadcast_targets(changes)
    capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { HouseBroadcast.changes(changes) }.map { |stream| stream["target"] }
  end

  test "a light change replaces its tiles in every section, the room heads, the summary and its open views" do
    changes = Hue::Mirror::Changes.new.tap { |pending| pending.lights_changed("l1") }
    targets = broadcast_targets(changes)
    assert_includes targets, "light_r1_l1"
    assert_includes targets, "light_z1_l1"
    assert_includes targets, "room_head_r1"
    assert_includes targets, "room_head_z1"
    assert_includes targets, "house_summary"
    assert_includes targets, "light_panel_l1"
    assert_includes targets, "floor_light_l1"
    refute_includes targets, "light_r1_l2"
  end

  test "a scene change replaces only its card" do
    changes = Hue::Mirror::Changes.new.tap { |pending| pending.scene_changed("s1") }
    assert_equal [ "scene_card_s1" ], broadcast_targets(changes)
  end

  test "nothing is broadcast for no changes" do
    assert_no_turbo_stream_broadcasts(HouseBroadcast::STREAM) { HouseBroadcast.changes(Hue::Mirror::Changes.new) }
  end
end
