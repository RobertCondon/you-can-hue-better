require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the everyday view shows every room and no logs" do
    get root_path
    assert_response :success
    assert_select ".compact section.room", 2
    assert_select "#light_r1_l1 .tile__name", "Desk lamp"
    assert_select "#light_z1_l1 .tile__name", "Desk lamp"
    assert_select "#house_summary", /1 of 2 on/
    assert_select ".activity", 0
    assert_select ".room__title[aria-expanded]", 2
    assert_select "[data-controller~=rooms] .room__editing", 2
    assert_select "svg path[d^=\"M9.5\"]", 0, "no pencil icons"
    assert_select ".views .views__link.is-current", "Lights"
    assert_select ".views a[href='#{floor_path}']", "Floor"
  end

  test "the dev view adds the logs" do
    get dev_path
    assert_response :success
    assert_select ".activity h2", "Recent changes"
    assert_select "#recent_presses"
    assert_select ".views a[href='#{root_path}']", "Lights"
  end

  test "shows whether the mirror is live" do
    get dev_path
    assert_select "#listener_status .status.is-live", "Live"
    Hue::ListenerState.current.disconnected!
    get root_path
    assert_select "#listener_status .status", /Not live/
  end

  test "explains when the bridge is unreachable and the mirror is empty" do
    Hue::Light.destroy_all
    Hue::ListenerState.current.disconnected!
    Hue.client = Object.new.tap { |c| c.define_singleton_method(:devices) { raise Hue::Error, "Can't reach the bridge at 10.0.0.1" } }
    get root_path
    assert_response :service_unavailable
    assert_select "h2", /Can't reach the Hue bridge/
  end
end
