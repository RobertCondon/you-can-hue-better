require "test_helper"
require "turbo/broadcastable/test_helper"

class HouseCommands::SettlementTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  TAB = "settling-tab"

  setup { sync_mirror! }

  def lamp_update = HouseCommands::LightUpdate.new(Hue::Light.find("l1"), ActionController::Parameters.new(on: "false").permit!)

  def settle(command = lamp_update)
    activity = ActivityRecorder.pending(target_kind: "light", target_id: "l1", target_name: "Desk lamp", action: "off")
    toasts = capture_turbo_stream_broadcasts(HouseBroadcast.tab_stream(TAB)) do
      HouseCommands::Settlement.new(command:, activity:, tab: TAB).settle
    end
    [ activity.reload, toasts ]
  end

  test "ok settles the row with no toast and broadcasts the truth" do
    house = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { @activity, @toasts = settle }
    assert_equal [ Activity::OK, [] ], [ @activity.result, @toasts ]
    assert_includes house.map { |stream| stream["target"] }, "light_r1_l1"
  end

  test "not responding keeps the change and warns" do
    hue.unpowered_light_ids << "l1"
    activity, toasts = settle
    assert activity.unreachable?
    assert_match(/isn't responding/, toasts.sole.to_html)
  end

  test "a light that was already showing as not responding is logged but doesn't warn again" do
    Hue::Device.find("d1").update!(reachable: false)
    hue.unpowered_light_ids << "l1"
    activity, toasts = settle
    assert activity.unreachable?
    assert_empty toasts
  end

  test "a rejection logs the reason, warns, and still broadcasts the truth" do
    hue.rejection_for_writes = "link button not pressed"
    house = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { @activity, @toasts = settle }
    assert_equal "link button not pressed", @activity.result
    assert_match(/link button not pressed/, @toasts.sole.to_html)
    assert_includes house.map { |stream| stream["target"] }, "light_r1_l1"
  end

  test "an unexpected error still settles the row before it is raised on" do
    command = lamp_update
    command.define_singleton_method(:deliver) { raise ArgumentError, "bug" }
    activity = ActivityRecorder.pending(target_kind: "light", target_id: "l1", target_name: "Desk lamp", action: "off")
    assert_raises(ArgumentError) { HouseCommands::Settlement.new(command:, activity:, tab: TAB).settle }
    assert_match(/Something went wrong changing Desk lamp/, activity.reload.result)
  end

  test "no tab means no toast" do
    hue.rejection_for_writes = "link button not pressed"
    activity = ActivityRecorder.pending(target_kind: "light", target_id: "l1", target_name: "Desk lamp", action: "off")
    assert_nothing_raised { HouseCommands::Settlement.new(command: lamp_update, activity:, tab: nil).settle }
  end
end
