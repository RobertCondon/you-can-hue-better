require "test_helper"

class Html::CustomScenesControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "the new scene modal shows the room's lights as they are and asks for a name" do
    get new_html_custom_scene_path(group_id: "r1")
    assert_response :success
    assert_select "form[action='#{custom_scenes_path}'] input[name='custom_scene[name]'][required]"
    assert_select "input[type=hidden][name='custom_scene[group_id]'][value=r1]"
    assert_select ".custom-scene__light", 2
    assert_select ".custom-scene__light", /Desk lamp\s*80%/
  end

  test "holding a custom scene opens it to rename or delete" do
    scene = CustomScene.create!(name: "Reading", group_id: "r1", lights_attributes: [ { hue_light_id: "l1", brightness: 40 } ])
    get edit_html_custom_scene_path(scene)
    assert_response :success
    assert_select "form[action='#{custom_scene_path(scene)}'] input[name='custom_scene[name]'][value=Reading]"
    assert_select "form.custom-scene__delete[action='#{custom_scene_path(scene)}'][data-controller=json-form][data-json-form-confirm-value] input[name=_method][value=delete]"
  end
end
