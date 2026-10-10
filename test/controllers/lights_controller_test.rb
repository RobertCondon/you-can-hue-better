require "test_helper"
require "turbo/broadcastable/test_helper"

class LightsControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  TAB = "tab-under-test"

  setup { sync_mirror! }

  def press(light_id, fields) = patch light_path(light_id), params: { light: fields }, headers: { HueCalls::TAB_HEADER => TAB }, as: :json

  def tab_broadcasts(&) = capture_turbo_stream_broadcasts(HouseBroadcast.tab_stream(TAB), &)

  test "a press is accepted straight away with a time to check in" do
    press("l1", on: "false")
    assert_response :accepted
    assert_equal [ [ :light, "l1", { on: { on: false } } ] ], hue.writes
    assert_equal %w[l1], response.parsed_body["light_ids"]
    assert_includes Hue::CallTimings::FLOOR_MILLISECONDS..Hue::CallTimings::CEILING_MILLISECONDS, response.parsed_body["check_in_ms"]
  end

  test "the truth goes to every tab, then the lights settle" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { press("l1", on: "false") }
    targets = streams.map { |stream| stream["target"] }
    assert_includes targets, "light_r1_l1"
    assert_includes targets, "light_panel_l1"
    assert_equal [ "settle", "l1" ], [ streams.last["action"], streams.last["light-ids"] ]
    refute Hue::Locks.locked?("l1")
  end

  test "brightness also turns the light on" do
    press("l2", brightness: "42")
    assert_equal [ [ :light, "l2", { on: { on: true }, dimming: { brightness: 42.0 } } ] ], hue.writes
  end

  test "colour is converted to xy" do
    press("l1", color: "#ff0000")
    assert_in_delta 0.64, hue.writes.first.last.dig(:color, :xy, :x), 0.01
  end

  test "the activity row ends up ok" do
    assert_difference "Activity.count", 1 do
      press("l1", on: "false")
    end
    activity = Activity.last
    assert_equal [ "light", "Desk lamp", "off", "ok" ], [ activity.target_kind, activity.target_name, activity.action, activity.result ]
  end

  test "a bridge error is logged and shown only to the tab that pressed" do
    hue.rejection_for_writes = "link button not pressed"
    toasts = tab_broadcasts { press("l1", on: "false") }
    assert_response :accepted
    assert_equal "link button not pressed", Activity.last.result
    assert_match(/link button not pressed/, toasts.sole.to_html)
    refute Hue::Locks.locked?("l1")
  end

  test "a bulb with no power keeps the change and warns the tab that pressed" do
    hue.unpowered_light_ids << "l1"
    toasts = tab_broadcasts { press("l1", on: "false") }
    assert_equal "not responding", Activity.last.result
    assert_match(/Desk lamp isn't responding/, toasts.sole.to_html)
  end

  test "a light another device is changing bounces with a message" do
    claim = Hue::Locks.claim(%w[l1])
    press("l1", on: "false")
    assert_response :conflict
    assert_empty hue.writes
    assert_equal({ "error" => "Desk lamp is being changed from another device. Try again in a moment.", "light_ids" => %w[l1] }, response.parsed_body)
  ensure
    Hue::Locks.release(claim)
  end

  test "the picker sends xy straight through" do
    press("l1", x: "0.6915", y: "0.3083")
    assert_equal [ [ :light, "l1", { on: { on: true }, color: { xy: { x: 0.6915, y: 0.3083 } } } ] ], hue.writes
    assert_match(/colour #/, Activity.last.action)
  end

  test "the white strip sends a colour temperature, clamped to the bulb's range" do
    press("l1", mirek: "9000")
    assert_equal [ [ :light, "l1", { on: { on: true }, color_temperature: { mirek: 500 } } ] ], hue.writes
    assert_equal "white 2000K", Activity.last.action
  end

  test "every page has its own tab id and stream" do
    get root_path
    tab = css_select("meta[name=hue-tab]").sole["content"]
    assert_predicate tab, :present?
    assert_select "turbo-cable-stream-source", minimum: 2
  end

  test "every page carries the toast the browser shows when a light is still changing" do
    get root_path
    assert_select "template[data-toast-template][data-toast-target=flash][data-still-changing='Still changing. Try again in a moment.']"
  end
end
