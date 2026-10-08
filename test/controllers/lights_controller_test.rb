require "test_helper"

class LightsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "toggle turns an on light off and refreshes every section it appears in" do
    patch light_path("l1"), params: { light: { on: "toggle" } }, as: :turbo_stream
    assert_response :success
    assert_equal [ [ :light, "l1", { on: { on: false } } ] ], hue.writes
    assert_select "turbo-stream[action=replace][target=light_r1_l1]"
    assert_select "turbo-stream[action=replace][target=light_z1_l1]"
    assert_select "turbo-stream[action=replace][target=room_head_r1]"
    assert_select "turbo-stream[action=update][target=house_summary]"
  end

  test "brightness also turns the light on" do
    patch light_path("l2"), params: { light: { brightness: "42" } }, as: :turbo_stream
    assert_equal [ [ :light, "l2", { on: { on: true }, dimming: { brightness: 42.0 } } ] ], hue.writes
  end

  test "colour is converted to xy" do
    patch light_path("l1"), params: { light: { color: "#ff0000" } }, as: :turbo_stream
    body = hue.writes.first.last
    assert_in_delta 0.64, body.dig(:color, :xy, :x), 0.01
  end

  test "records an activity row" do
    assert_difference "Activity.count", 1 do
      patch light_path("l1"), params: { light: { on: "false" } }, as: :turbo_stream
    end
    a = Activity.last
    assert_equal [ "light", "Desk lamp", "off", "ok" ], [ a.target_kind, a.target_name, a.action, a.result ]
  end

  test "bridge errors are shown in the flash and logged" do
    hue.rejection_for_writes = "link button not pressed"
    patch light_path("l1"), params: { light: { on: "toggle" } }, as: :turbo_stream
    assert_select "turbo-stream[action=update][target=flash]", /link button not pressed/
    assert_equal "link button not pressed", Activity.last.result
  end
end

class LightsControllerUnreachableTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "a bulb with no power still updates but warns the person" do
    hue.unpowered_light_ids << "l1"
    patch light_path("l1"), params: { light: { on: "toggle" } }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=replace][target=light_r1_l1]"
    assert_select "turbo-stream[action=update][target=flash]", /Desk lamp isn't responding/
    assert_equal "not responding", Activity.last.result
  end

  test "a successful change clears any earlier message" do
    patch light_path("l1"), params: { light: { on: "toggle" } }, as: :turbo_stream
    assert_select "turbo-stream[action=update][target=flash]" do |el|
      assert_equal "", el.text.strip
    end
  end
end

class LightsControllerPickerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the picker sends xy straight through" do
    patch light_path("l1"), params: { light: { x: "0.6915", y: "0.3083" } }, as: :turbo_stream
    assert_equal [ [ :light, "l1", { on: { on: true }, color: { xy: { x: 0.6915, y: 0.3083 } } } ] ], hue.writes
    assert_match(/colour #/, Activity.last.action)
  end

  test "the white strip sends a colour temperature, clamped to the bulb's range" do
    patch light_path("l1"), params: { light: { mirek: "9000" } }, as: :turbo_stream
    assert_equal [ [ :light, "l1", { on: { on: true }, color_temperature: { mirek: 500 } } ] ], hue.writes
    assert_equal "white 2000K", Activity.last.action
  end

  test "tiles are plain and open a panel; the panel carries the colour component" do
    get root_path
    assert_select "#light_r1_l1 .tile__open[data-light-panel-pin-url-param='#{pin_light_path("l1")}']"
    assert_select "#light_r1_l1 input", 0, "no form controls in the row; the drag is the slider"
    assert_select "main[data-controller=light-panel]"

    get panel_light_path("l1")
    assert_response :success
    assert_select "#light_panel_l1[data-color-picker-mode-value=ct][data-color-picker-mirek-value='359']"
    assert_select "#light_panel_l1[data-color-picker-gamut-value*='0.6915']"
    assert_select "#light_panel_l1 .switch input[type=checkbox][checked]"
    assert_select "#light_panel_l1 input[type=range][value='80']"
    assert_select "#light_panel_l1 output", "80%"
    assert_select "#light_panel_l1 .light-panel__name[data-editor-url-param='#{light_names_path("l1")}']"
  end

  test "an update also refreshes the panel" do
    patch light_path("l1"), params: { light: { on: "false" } }, as: :turbo_stream
    assert_select "turbo-stream[action=replace][target=light_panel_l1] .switch input[type=checkbox]:not([checked])"
  end
end
