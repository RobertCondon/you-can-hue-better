require "test_helper"
require "turbo/broadcastable/test_helper"

class CustomScenesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup { sync_mirror! }

  test "saving from the modal captures how the room's lights look right now" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      post custom_scenes_path, params: { custom_scene: { name: "Reading", group_id: "r1" } }, as: :turbo_stream
    end
    assert_response :success
    scene = CustomScene.sole
    assert_equal [ "Reading", "r1" ], [ scene.name, scene.group_id ]
    desk = scene.lights.find_by!(hue_light_id: "l1")
    assert_equal [ true, 80.0, 359, nil ], [ desk.on, desk.brightness.to_f, desk.mirek, desk.color_x ]
    refute scene.lights.find_by!(hue_light_id: "l2").on
    assert_select "turbo-stream[action=replace][target=room_r1] .chip--custom", "Reading"
    assert_includes streams.map { |stream| stream["target"] }, "room_r1"
  end

  test "a scene with no name shows why in the modal" do
    post custom_scenes_path, params: { custom_scene: { name: "", group_id: "r1" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=update][target=custom_scene_error]", /Name can't be blank/
    assert_equal 0, CustomScene.count
  end

  test "a room lists its custom scenes after its own scenes, then the add button" do
    CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40, mirek: 366 } ])
    get root_path
    chips = css_select("#room_r1 .scenes .chip").map { |chip| chip.text.strip }
    assert_equal [ "Bright", "Relax", "Reading", "+" ], chips
    scene = CustomScene.sole
    assert_select "#room_r1 form.chip-form[action$='/activation'][data-controller~=async-hue-call][data-controller~=scene-hold] .chip--custom", "Reading"
    assert_select "#room_r1 form.chip-form[data-action*='scene-hold:edit->custom-scene-dialog#open'][data-custom-scene-dialog-url-param='#{edit_html_custom_scene_path(scene)}']"
    targets = JSON.parse(css_select("#room_r1 form.chip-form[action$='/activation']").sole["data-async-hue-call-targets-value"])
    assert_equal [ { "light_id" => "l1", "on" => true, "level" => 40, "hex" => Hue::Color.mirek_to_hex(366) } ], targets
    assert_select "#room_r1 .chip--add[data-action='custom-scene-dialog#open'][data-custom-scene-dialog-url-param='#{new_html_custom_scene_path(group_id: "r1")}']"
  end

  test "renaming from the modal updates the room everywhere" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40 } ])
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      patch custom_scene_path(scene), params: { custom_scene: { name: "Late reading" } }, as: :turbo_stream
    end
    assert_equal "Late reading", scene.reload.name
    assert_equal 1, scene.lights.count
    assert_select "turbo-stream[action=replace][target=room_r1] .chip--custom", "Late reading"
    assert_includes streams.map { |stream| stream["target"] }, "room_r1"
  end

  test "deleting from the modal removes the scene and its chip" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40 } ])
    delete custom_scene_path(scene), as: :turbo_stream
    assert_equal 0, CustomScene.count
    assert_select "turbo-stream[action=replace][target=room_r1]"
    assert_select "turbo-stream[action=replace][target=room_r1] .chip--custom", 0
  end

  test "a blank name on rename shows why in the modal" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40 } ])
    patch custom_scene_path(scene), params: { custom_scene: { name: "" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "Reading", scene.reload.name
  end

  test "a custom scene can be deleted along with its lights" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40 } ])
    assert_difference [ "CustomScene.count", "CustomSceneLight.count" ], -1 do
      scene.destroy!
    end
  end

  test "pressing a custom scene moves its lights there straight away" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40, mirek: 366 } ])
    post custom_scene_activation_path(scene), as: :turbo_stream
    assert_response :accepted
    assert_equal [ [ :light, "l1", { on: { on: true }, dynamics: { duration: 400 }, dimming: { brightness: 40.0 }, color_temperature: { mirek: 366 } } ] ], hue.writes
  end

  test "creates a scene with its lights" do
    post custom_scenes_path, params: { custom_scene: { name: "Evening", group_id: "r1", lights_attributes: [
      { hue_light_id: "l1", brightness: 40, mirek: 366 },
      { hue_light_id: "l2", color_x: 0.5, color_y: 0.4 }
    ] } }, as: :json
    assert_response :created
    body = response.parsed_body
    assert_equal "Evening", body["name"]
    assert_equal [ [ "l1", 40.0, 366 ], [ "l2", nil, nil ] ], body["lights"].map { |light| light.values_at("hue_light_id", "brightness", "mirek") }
  end

  test "updates, adds and removes a scene's lights" do
    scene = CustomScene.create!(name: "Evening", lights_attributes: [ { hue_light_id: "l1", mirek: 366 } ])
    light = scene.lights.first
    patch custom_scene_path(scene), params: { custom_scene: { name: "Late", lights_attributes: [
      { id: light.id, _destroy: true },
      { hue_light_id: "l2", mirek: 250 }
    ] } }, as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal "Late", body["name"]
    assert_equal [ [ "l2", 250 ] ], body["lights"].map { |light_json| light_json.values_at("hue_light_id", "mirek") }
  end

  test "a light with both a colour and a mirek is refused" do
    post custom_scenes_path, params: { custom_scene: { name: "Bad", lights_attributes: [ { hue_light_id: "l1", color_x: 0.3, color_y: 0.3, mirek: 366 } ] } }, as: :json
    assert_response :unprocessable_entity
    assert_equal 0, CustomScene.count
  end

  test "shows a scene as json" do
    scene = CustomScene.create!(name: "Evening", lights_attributes: [ { hue_light_id: "l1", brightness: 50 } ])
    get custom_scene_path(scene, format: :json)
    assert_response :success
    assert_equal [ "l1" ], response.parsed_body["lights"].map { |light| light["hue_light_id"] }
  end
end
