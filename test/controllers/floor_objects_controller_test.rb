require "test_helper"

class FloorObjectsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  def add_object(kind) = Floor::Item.create_centred!(group_id: Floor.home.id, kind:)

  test "adding a wall returns its element, centred with a default size" do
    post floor_objects_path, params: { kind: "wall" }
    assert_response :created
    wall = Floor::Item.last
    assert_equal [ "wall", Floor.home.id, 35.0, 48.5, 30.0, 3.0 ], [ wall.kind, wall.group_id, wall.x.to_f, wall.y.to_f, wall.w.to_f, wall.h.to_f ]
    assert_select ".floor__object--wall[data-kind=wall][data-url='#{floor_object_path(wall)}'] .floor__handle"
    assert_select ".floor__object--wall .floor__rotate", 1
    assert_select ".floor__object--wall[style*='--r: 0']"
  end

  test "an unknown kind is refused" do
    post floor_objects_path, params: { kind: "pony" }
    assert_response :unprocessable_entity
  end

  test "moving and resizing saves, clamped" do
    box = add_object("box")
    patch floor_object_path(box), params: { x: "80", y: "-3", w: "250", h: "10", rotation: "-30", label: " Sofa " }
    assert_response :no_content
    box.reload
    assert_equal [ 80.0, 0.0, 100.0, 10.0, 330, "Sofa" ], [ box.x.to_f, box.y.to_f, box.w.to_f, box.h.to_f, box.rotation, box.label ]
  end

  test "the floor renders its objects and the light canvas" do
    add_object("circle").update!(label: "Table")
    get floor_path
    assert_select ".floor canvas.floor__light"
    assert_select ".floor__object--circle .floor__label", "Table"
    assert_select ".floor-head button[data-floor-kind-param=wall]"
  end

  test "a scene's floor shows the house's objects but no editing controls" do
    add_object("wall")
    get scene_path("s1")
    assert_select ".floor__object--wall", 1
    assert_select ".floor__object .floor__handle", 0
  end

  test "rounds have no rotate handle" do
    add_object("circle")
    get floor_path
    assert_select ".floor__object--circle .floor__rotate", 0
  end

  test "the live floor has a selection toolbar" do
    get floor_path
    assert_select "[data-floor-target=selection] button[data-floor-degrees-param='15']"
    assert_select "[data-floor-target=selection] button", /Remove/
  end

  test "a scene's floor state is what each light would look like" do
    get floor_state_scene_path("s1"), as: :json
    assert_response :success
    states = response.parsed_body.index_by { |state| state["light_id"] }
    assert_equal [ true, 0.38 ], [ states["l1"]["on"], states["l1"]["bri"] ]
    assert_match(/\A#[0-9a-f]{6}\z/, states["l2"]["hex"])
    assert_empty hue.writes, "previewing never touches the bridge"
  end

  test "removing" do
    box = add_object("box")
    delete floor_object_path(box)
    assert_response :no_content
    refute Floor::Item.exists?(box.id)
  end
end
