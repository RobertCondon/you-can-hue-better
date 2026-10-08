require "test_helper"

class NamesControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "a light nickname shows as the name with the real name underneath" do
    patch light_names_path("l1"), params: { light: { nickname: "  Reading light " } }, as: :turbo_stream
    assert_response :success
    assert_equal "Reading light", HueExtensions::Light.find("l1").nickname
    assert_empty hue.writes, "nicknames never touch the bridge"
    assert_select "turbo-stream[target=light_r1_l1] .tile__name", "Reading light"
    assert_select "turbo-stream[target=light_r1_l1] .tile__realname", "Desk lamp"
    assert_select "turbo-stream[target=light_z1_l1]", 1, "every section showing the light updates"
  end

  test "an empty nickname clears it" do
    HueExtensions::Light.set_nickname!("l1", "Old")
    patch light_names_path("l1"), params: { light: { nickname: "" } }, as: :turbo_stream
    assert_nil HueExtensions::Light.find("l1").nickname
    assert_select "turbo-stream[target=light_r1_l1] .tile__realname", 0
  end

  test "renaming a light renames the bulb and its device on the bridge" do
    patch light_names_path("l1"), params: { light: { name: "Lamp", nickname: "" } }, as: :turbo_stream
    assert_response :success
    assert_equal [ [ :rename_light, "l1", "Lamp" ], [ :rename_device, "d1", "Lamp" ] ], hue.writes
    assert_equal "Lamp", Hue::Light.find("l1").name
    assert_equal "Lamp", Hue::Device.find("d1").name
    assert_equal "rename to Lamp", Activity.last.action
  end

  test "an unchanged name is not sent to the bridge" do
    patch light_names_path("l1"), params: { light: { name: "Desk lamp", nickname: "x" } }, as: :turbo_stream
    assert_empty hue.writes
  end

  test "the bridge's rejection keeps the editor open with the reason" do
    patch light_names_path("l1"), params: { light: { name: "x" * 33 } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_select "turbo-stream[target=editor_error]", /maxLength/
    assert_equal "Desk lamp", Hue::Light.find("l1").name
  end

  test "a room nickname shows with the real name above" do
    patch room_names_path("r1"), params: { room: { nickname: "Office" } }, as: :turbo_stream
    assert_select "turbo-stream[target=room_head_r1] h2", /Office/
    assert_select "turbo-stream[target=room_head_r1] .room__realname", "Study"
  end

  test "renaming a zone renames it on the bridge" do
    patch room_names_path("z1"), params: { room: { name: "Night" } }, as: :turbo_stream
    assert_equal [ [ :rename_group, "zone", "z1", "Night" ] ], hue.writes
    assert_equal "Night", Hue::Group.find("z1").name
  end

  test "only the dev view offers bridge renames" do
    get root_path
    assert_select ".editor input[data-editor-target=name]", 0
    assert_select ".editor input[data-editor-target=nickname]", 1
    get dev_path
    assert_select ".editor input[data-editor-target=name]", 1
  end
end
