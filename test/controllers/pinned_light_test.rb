require "test_helper"
require "turbo/broadcastable/test_helper"

class PinnedLightTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  setup { sync_mirror! }

  test "the lights view docks a light's sheet at the bottom and tiles open into it" do
    get root_path
    assert_select "main[data-controller~=light-panel] > .light-dock#light_dock[hidden][data-light-panel-target=dock]"
    assert_select "#light_r1_l1 .tile__open[data-light-panel-sheet-url-param='#{sheet_html_light_path("l1")}'][data-light-panel-room-param=r1][aria-controls=light_dock]"
  end

  test "a sheet has the switch, the name, a close button, the brightness and the colour picker" do
    get sheet_html_light_path("l1")
    assert_response :success
    assert_select "#light_sheet_l1.is-on[data-controller~=pinned][data-controller~=light][style*='--fill: 80%']"
    assert_select "#light_sheet_l1 form.light-sheet__toggle[data-controller=async-hue-call] button[role=switch][aria-checked=true][name='light[on]'][value=false]"
    assert_select "#light_sheet_l1 .light-sheet__name[data-editor-url-param='#{light_names_path("l1")}'] span", "Desk lamp"
    assert_select "#light_sheet_l1 .light-sheet__close[data-action='pinned#close']"
    assert_select "#light_sheet_l1 form.light-sheet__dim input[type=range][value='80']"
    assert_select "#light_sheet_l1 form.light-sheet__dim output", "80%"
    assert_select "#light_sheet_l1 #light_panel_l1[data-controller~=color-picker]"
  end

  test "a pin is a bar plus the folded panel" do
    get pin_html_light_path("l1")
    assert_response :success
    assert_select "#light_pin_l1[data-controller~=pinned][data-controller~=light][style*='--fill: 80%']"
    assert_select "#light_pin_l1 .pin__bar .pin__icon[aria-pressed=true] svg.ico"
    assert_select "#light_pin_l1 .pin__bar .pin__name", "Desk lamp"
    assert_select "#light_pin_l1 .pin__bar [data-level]", "80%"
    assert_select "#light_pin_l1 .pin__bar input[type=range][value='80']"
    assert_select "#light_pin_l1 .pin__bar .pin__swatch[data-action='pinned#expand']"
    assert_select "#light_pin_l1 form.pin__toggle[data-controller=async-hue-call][data-async-hue-call-light-ids-value='[\"l1\"]'] button[name='light[on]'][value=false]"
    assert_select "#light_pin_l1 form.pin__dim[data-action*='submit->async-hue-call#submit']"
    assert_select "#light_pin_l1 .pin__sheet #light_panel_l1 .switch input[checked]"
  end

  test "an update refreshes the pin and the sheet too" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      patch light_path("l1"), params: { light: { brightness: "42" } }, as: :json
    end
    pin = streams.find { |stream| stream["target"] == "light_pin_l1" }
    assert_equal "42%", pin.at_css(".pin__bar [data-level]").text.strip
    sheet = streams.find { |stream| stream["target"] == "light_sheet_l1" }
    assert_equal "42%", sheet.at_css(".light-sheet__dim output").text.strip
  end

  test "the floor carries a dock for phones" do
    get floor_path
    assert_select ".floor-wrap[data-action*='pinned:close->floor#dockClosed'] .dock--floor[data-floor-target=dock][hidden] + .floor"
  end
end
