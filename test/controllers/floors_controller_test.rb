require "test_helper"

class FloorsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the house floor shows every light once, unplaced ones along the bottom" do
    get floor_path
    assert_response :success
    assert_select ".floor .floor__lamp", 2
    assert_select ".floor__lamp.is-unplaced", 2
    assert_select "#floor_light_l1[style*='--y: 86.0'][data-rooms~=r1][data-rooms~=z1]"
    assert_select ".floor-head__hint", /2 lights not placed/
  end

  test "dropping a light saves its spot on the house floor, clamped" do
    patch floor_path, params: { light_id: "l1", x: "33.333", y: "120" }
    assert_response :no_content
    p = LightPlacement.find_by!(light_id: "l1")
    assert_equal [ Floor.home.id, 33.33, 100.0 ], [ p.group_id, p.x.to_f, p.y.to_f ]
    get floor_path
    assert_select "#floor_light_l1[style*='--x: 33.33']:not(.is-unplaced)"
  end

  test "the shape is saved on the home group's extension" do
    patch floor_path, params: { aspect: "1.6" }
    assert_equal 1.6, HueExtensions::Group.find(Floor.home.id).floor_aspect.to_f
    get floor_path
    assert_select ".floor[style*='--aspect: 1.6']"
  end

  test "filters are chips: Everything, each room, and each room's scenes beneath it" do
    get floor_path
    assert_select ".chips--filters .chip[data-floor-room-param=''][aria-pressed=true]", "Everything"
    assert_select ".chips--filters .chip[data-floor-room-param=r1]", /Study/
    assert_select ".chips--scenes[data-room=r1][hidden] .chip--scene", 2
    assert_select ".chips--scenes[data-room=z1] .chip--scene[data-floor-url-param='#{floor_state_scene_path("s3")}'][data-floor-set-url-param='#{activate_scene_path("s3")}']", "Dusk"
    assert_select ".chips--scenes[data-room=r1] form[data-floor-target=setForm][hidden]"
    assert_select ".views .views__link.is-current", "Floor"
  end

  test "the editing tools sit in a bar above the floor, never over it" do
    get floor_path
    assert_select ".floor-head .tool--toggle[data-action='floor#toggleEdit']"
    assert_select ".floor-head [data-floor-target=tools][hidden] .tool[data-floor-kind-param=wall]"
    assert_select ".floor-head [data-floor-target=selection][hidden] .tool--danger", "Remove"
    assert_select ".floor .tool", 0
  end

  test "a light's glow follows its state" do
    get floor_path
    assert_select "#floor_light_l1.is-on[style*='--bri: 0.8']"
    assert_select "#floor_light_l2.is-off[style*='--bri: 0']"
  end
end

class FloorLightPanelTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "a lamp opens its live panel; the floor carries the popover and the rename dialog" do
    get floor_path
    assert_select "#floor_light_l1[data-action~='click->floor#openLight'][data-floor-panel-url-param='#{panel_light_path("l1")}']"
    assert_select ".floor-wrap .floor__popover[hidden] [data-floor-target=popoverBody]"
    assert_select "main[data-controller=editor] .editor input[data-editor-target=nickname]"
    assert_select "main .editor input[data-editor-target=name]", 0, "nicknames only, like the everyday view"
  end

  test "a scene's floor has no live panel" do
    get scene_path("s1")
    assert_select ".floor__popover", 0
  end
end

class FloorUnreachableTest < ActionDispatch::IntegrationTest
  setup { sync_mirror!; Hue::Device.find("d1").update!(reachable: false) }

  test "an unreachable bulb is drawn off and marked, in the rows, on the floor, and in its panel" do
    get root_path
    assert_select "#light_r1_l1.is-off.is-unreachable .tile__level", "Not responding"
    get floor_path
    assert_select "#floor_light_l1.is-off.is-unreachable[style*='--bri: 0']"
    get panel_light_path("l1")
    assert_select ".light-panel__notice", /Not responding.*on at 80%/
    get floor_state_scene_path("s1"), as: :json
    assert_equal 0, response.parsed_body.find { _1["light_id"] == "l1" }["bri"], "a scene preview can't light a bulb with no power"
  end
end

class FloorCameraTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the floor is a viewport over a world, with zoom controls and a label level" do
    get floor_path
    assert_select ".floor[data-level=far][data-action*='wheel->floor#wheel']"
    assert_select ".floor .floor__world[data-floor-target=world] .floor__lamp", 2
    assert_select ".floor .floor__zoom button", 3
    assert_select ".floor__lamp .floor__dot svg.ico", 2, "every lamp carries its glyph"
  end

  test "the icon comes from the bulb's archetype" do
    Hue::Device.find("d1").update!(raw: Hue::Device.find("d1").raw.deep_merge("product_data" => { "product_archetype" => "candle_bulb" }))
    get floor_path
    assert_select "#floor_light_l1 .floor__dot svg rect[x='6']", 1, "the candle glyph"
  end
end
