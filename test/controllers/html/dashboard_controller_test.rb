require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the everyday view shows every room and no logs" do
    get root_path
    assert_response :success
    assert_select ".compact .room-pager > section.room-card", 2
    assert_select "#light_r1_l1 .tile__name", "Desk lamp"
    assert_select "#light_z1_l1 .tile__name", "Desk lamp"
    assert_select "#house_summary", /1 of 2 on/
    assert_select ".activity", 0
    assert_select ".room-tabs[role=tablist] .room-tab[role=tab][data-action='room-pager#select']", 2
    assert_select "#room_tab_r1[aria-controls=room_body_r1][data-room-pager-room-param=r1]"
    assert_select ".room__body[role=tabpanel]", 2
    assert_select "#room_body_z1[hidden]"
    assert_select ".room-pager__dots span[data-room-pager-target=dot]", 2
    assert_select "[data-controller~=rooms] dialog.all-rooms .room-row .room-row__editing", 2
    assert_select "svg path[d^=\"M9.5\"]", 0, "no pencil icons"
    assert_select ".views .views__link.is-current", "Lights"
    assert_select ".views a[href='#{floor_path}']", "Floor"
  end

  test "all rooms opens from the end of the tab row and lists every room with its own switch" do
    get root_path
    assert_select ".room-tabbar > .room-tabbar__all[data-action='all-rooms#open'][aria-haspopup=dialog]"
    assert_select "main[data-controller~=all-rooms] > dialog.all-rooms[data-all-rooms-target=dialog]"
    assert_select "dialog.all-rooms [data-action='rooms#toggleEditing'][data-rooms-target=editButton]", "Edit"
    assert_select "dialog.all-rooms .room-row", 2
    assert_select "#room_row_r1[data-room-pager-target=row][style='--fill: 80%'] .room-row__go[data-action='room-pager#select all-rooms#close'][data-room-pager-room-param=r1]"
    assert_select "#room_row_r1 form.room-row__toggle[data-controller=async-hue-call] .room-card__switch[role=switch][aria-checked=true]"
    assert_select "#room_row_r1 .room-dots__dot[data-light-id]", 2
    assert_select ".house [data-action='rooms#toggleEditing']", 0, "Edit lives in All rooms now"
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
    Hue.client = Object.new.tap { |unreachable| unreachable.define_singleton_method(:devices) { raise Hue::Error, "Can't reach the bridge at 10.0.0.1" } }
    get root_path
    assert_response :service_unavailable
    assert_select "h2", /Can't reach the Hue bridge/
  end
end
