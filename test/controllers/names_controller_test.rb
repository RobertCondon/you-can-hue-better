require "test_helper"
require "turbo/broadcastable/test_helper"

class NamesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup { sync_mirror! }

  test "the rename editor sends through the direct form controller and closes when it ends" do
    get root_path
    assert_select "dialog.editor form[data-controller=direct-hue-call][data-action*='submit->direct-hue-call#submit'][data-action*='direct-hue-call:end->editor#submitted']"
  end

  test "a rename waits for the bridge even while another device is changing that light" do
    claim = Hue::Locks.claim(%w[l1])
    patch light_names_path("l1"), params: { light: { name: "Reading lamp" } }, as: :json
    assert_response :success
    assert_includes hue.writes.map(&:first), :rename_light
  ensure
    Hue::Locks.release(claim)
  end

  test "a light nickname shows as the name with the real name underneath" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      patch light_names_path("l1"), params: { light: { nickname: "  Reading light " } }, as: :json
    end
    assert_response :success
    assert_equal({ "id" => "l1", "name" => "Desk lamp", "nickname" => "Reading light" }, response.parsed_body)
    assert_empty hue.writes, "nicknames never touch the bridge"
    tile = streams.find { |stream| stream["target"] == "light_r1_l1" }
    assert_equal [ "Reading light", "Desk lamp" ], [ tile.at_css(".tile__name").text.strip, tile.at_css(".tile__realname").text.strip ]
    assert_includes streams.map { |stream| stream["target"] }, "light_z1_l1", "every section showing the light updates"
  end

  test "an empty nickname clears it" do
    HueExtensions::Light.set_nickname!("l1", "Old")
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { patch light_names_path("l1"), params: { light: { nickname: "" } }, as: :json }
    assert_nil HueExtensions::Light.find("l1").nickname
    assert_empty streams.find { |stream| stream["target"] == "light_r1_l1" }.css(".tile__realname")
  end

  test "renaming a light renames the bulb and its device on the bridge" do
    patch light_names_path("l1"), params: { light: { name: "Lamp", nickname: "" } }, as: :json
    assert_response :success
    assert_equal [ [ :rename_light, "l1", "Lamp" ], [ :rename_device, "d1", "Lamp" ] ], hue.writes
    assert_equal "Lamp", Hue::Light.find("l1").name
    assert_equal "Lamp", Hue::Device.find("d1").name
    assert_equal "rename to Lamp", Activity.last.action
  end

  test "a bridge rename reaches every open page, not just this one" do
    broadcasts = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      patch light_names_path("l1"), params: { light: { name: "Reading lamp" } }, as: :json
    end
    assert_includes broadcasts.map { |stream| stream["target"] }, "light_r1_l1"
  end

  test "an unchanged name is not sent to the bridge" do
    patch light_names_path("l1"), params: { light: { name: "Desk lamp", nickname: "x" } }, as: :json
    assert_empty hue.writes
  end

  test "the bridge's rejection comes back with the reason for the editor to show" do
    patch light_names_path("l1"), params: { light: { name: "x" * 33 } }, as: :json
    assert_response :bad_gateway
    assert_match(/maxLength/, response.parsed_body["error"])
    assert_equal "Desk lamp", Hue::Light.find("l1").name
  end

  test "a room nickname shows with the real name above" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { patch room_names_path("r1"), params: { room: { nickname: "Office" } }, as: :json }
    assert_equal({ "id" => "r1", "name" => "Study", "nickname" => "Office" }, response.parsed_body)
    head = streams.find { |stream| stream["target"] == "room_head_r1" }
    assert_match(/Office/, head.at_css("h2").text)
    assert_equal "Study", head.at_css(".room__realname").text.strip
  end

  test "renaming a zone renames it on the bridge" do
    patch room_names_path("z1"), params: { room: { name: "Night" } }, as: :json
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
