require "test_helper"

class FloorPaintsControllerTest < ActionDispatch::IntegrationTest
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

  test "Apply sends one command per light, offers Undo, and refreshes the painted lamps" do
    hue.writes.clear
    strokes = [ { light_id: "l1", hex: "#ff0000" }, { light_id: "l2", mirek: 370 } ]
    post floor_paint_path, params: { strokes: strokes.to_json }, as: :turbo_stream
    assert_response :success

    sent = hue.writes.select { _1[0] == :light }.to_h { [ _1[1], _1[2] ] }
    assert_equal({ on: { on: true }, color: { xy: Hue::Color.hex_to_xy("#ff0000") } }, sent["l1"])
    assert_equal({ on: { on: true }, color_temperature: { mirek: 370 } }, sent["l2"])

    undo = UndoAction.last
    assert_equal "Painted 2 lights", undo.description
    assert_equal %w[l1 l2], undo.states.map { _1["light_id"] }.sort
    assert_select "turbo-stream[action=replace][target=floor_light_l1]"
    assert_select "turbo-stream[action=update][target=flash] .flash--undo form[action='#{undo_path(undo)}']"
    assert_equal "paint 2", Activity.last.action
  end

  test "unknown lights are ignored and an empty paint is refused" do
    post floor_paint_path, params: { strokes: [ { light_id: "nope", hex: "#ff0000" } ].to_json }, as: :turbo_stream
    assert_response :unprocessable_entity
  end
end
