require "test_helper"

class CustomScenesControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

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
