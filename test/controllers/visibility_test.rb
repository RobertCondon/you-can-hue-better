require "test_helper"

class VisibilityTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "a light hidden in /dev leaves the everyday views, the floor and the counts, but stays in /dev" do
    patch light_visibility_path("l2"), params: { light: { hidden: "true" } }
    assert_redirected_to dev_path(anchor: "visibility")

    get root_path
    assert_select "#light_r1_l2", 0
    assert_select "#light_r1_l1"
    assert_select "#room_head_r1 .room__summary", "All on"
    get floor_path
    assert_select "#floor_light_l2", 0
    get dev_path
    assert_select "#light_r1_l2 .tile__badge", "hidden"
    assert_select "#room_head_r1 .room__summary", "All on", "counts are of visible lights on /dev too"
    assert_select "#visibility_light_l2 input[name='light[hidden]'][type=checkbox][checked]"
  end

  test "a hidden room disappears everywhere outside /dev" do
    patch room_visibility_path("z1"), params: { room: { hidden: "true" } }
    get root_path
    assert_select "#room_z1", 0
    get scenes_path
    assert_select "main.scenes-page"
    assert_select "#scene_card_s3", 0
    get dev_path
    assert_select "#room_head_z1 .room__kind", /hidden/
  end

  test "off the floor without hiding, and an icon override" do
    patch light_visibility_path("l1"), params: { light: { on_floor: "false" } }
    patch light_visibility_path("l1"), params: { light: { icon: "candle" } }
    get floor_path
    assert_select "#floor_light_l1", 0
    get root_path
    assert_select "#light_r1_l1"
    assert_equal "candle", House.load(refresh: false).light("l1").icon
    patch light_visibility_path("l1"), params: { light: { icon: "" } }
    assert_equal "lamp", House.load(refresh: false).light("l1").icon
  end

  test "the dev page lists every room and light with their controls" do
    get dev_path
    assert_select "#visibility .visibility__table", 2
    assert_select "#visibility_room_r1 input[name='room[hidden]'][type=checkbox]:not([checked])"
    assert_select "#visibility_light_l1 select[name='light[icon]'] option[value=candle]"
    assert_select "#visibility_light_l1 input[name='light[on_floor]'][type=checkbox][checked]"
    assert_select "#visibility_light_l1 form[data-controller=autosave]", 3
  end

  test "the views nav carries icons for the phone tab bar" do
    get root_path
    assert_select "nav.views .views__link[aria-current=page] svg.views__icon", 1
    assert_select "nav.views .views__link svg.views__icon", 3
  end
end
