require "test_helper"
require "turbo/broadcastable/test_helper"

class FloorPaintsControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  setup { sync_mirror! }

  test "the floor has a Paint toggle, the tray with whites and colours, and scene chips carry their palette" do
    get floor_path
    assert_select ".floor-head [data-floor-target=paintButton][aria-pressed=false]", /Paint/
    assert_select "[data-floor-target=tray][hidden] .swatch[data-floor-mirek-param='370']"
    assert_select "[data-floor-target=tray] .swatch[data-floor-hex-param='#ff3b30']"
    assert_select "[data-floor-target=tray] input[type=range][data-floor-target=hueSlider]"
    assert_select "[data-floor-target=tray] [data-floor-target=paintApply][hidden]", "Apply"
    assert_select ".chip--scene[data-floor-palette-param]"
  end

  test "Apply sends one command per light and refreshes the painted lamps" do
    hue.writes.clear
    strokes = [ { light_id: "l1", hex: "#ff0000" }, { light_id: "l2", mirek: 370 } ]
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      post floor_paint_path, params: { strokes: strokes.to_json }, as: :turbo_stream
    end
    assert_response :accepted

    sent = hue.writes.select { |write| write.first == :light }.to_h { |_kind, light_id, changes| [ light_id, changes ] }
    assert_equal({ on: { on: true }, color: { xy: Hue::Color.hex_to_xy("#ff0000") } }, sent["l1"])
    assert_equal({ on: { on: true }, color_temperature: { mirek: 370 } }, sent["l2"])

    assert_includes streams.map { |stream| stream["target"] }, "floor_light_l1"
    assert_equal [ "paint 2", "ok" ], [ Activity.last.action, Activity.last.result ]
  end

  test "a white is kept within the range bulbs accept" do
    post floor_paint_path, params: { strokes: [ { light_id: "l1", mirek: 900 } ].to_json }, as: :turbo_stream
    assert_equal({ on: { on: true }, color_temperature: { mirek: 500 } }, hue.writes.last.last)
  end

  test "unknown lights are ignored and an empty paint is refused" do
    post floor_paint_path, params: { strokes: [ { light_id: "nope", hex: "#ff0000" } ].to_json }, as: :turbo_stream
    assert_response :unprocessable_entity
  end
end
