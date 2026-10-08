require "test_helper"

class PinnedLightTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the dock sits at the top of the lights view and tiles pin into it" do
    get root_path
    assert_select "main[data-controller=light-panel] > .dock#light_dock[hidden][data-light-panel-target=dock]"
    assert_select "#light_r1_l1 .tile__open[data-light-panel-pin-url-param='#{pin_light_path("l1")}'][data-light-panel-room-param=r1][aria-controls=light_dock]"
  end

  test "a pin is a bar plus the folded panel" do
    get pin_light_path("l1")
    assert_response :success
    assert_select "#light_pin_l1[data-controller~=pinned][data-controller~=light][style*='--fill: 80%']"
    assert_select "#light_pin_l1 .pin__bar .pin__icon[aria-pressed=true] svg.ico"
    assert_select "#light_pin_l1 .pin__bar .pin__name", "Desk lamp"
    assert_select "#light_pin_l1 .pin__bar [data-level]", "80%"
    assert_select "#light_pin_l1 .pin__bar input[type=range][value='80']"
    assert_select "#light_pin_l1 .pin__bar .pin__swatch[data-action='pinned#expand']"
    assert_select "#light_pin_l1 .pin__sheet #light_panel_l1 .switch input[checked]"
  end

  test "an update refreshes the pin too" do
    patch light_path("l1"), params: { light: { brightness: "42" } }, as: :turbo_stream
    assert_select "turbo-stream[action=replace][target=light_pin_l1] .pin__bar [data-level]", "42%"
  end

  test "the floor carries a dock for phones" do
    get floor_path
    assert_select ".floor-wrap[data-action*='pinned:close->floor#dockClosed'] .dock--floor[data-floor-target=dock][hidden] + .floor"
  end
end
