require "test_helper"
require "turbo/broadcastable/test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  setup { sync_mirror! }

  test "turns a whole room off via its grouped light, straight away" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) do
      patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    end
    assert_response :accepted
    assert_equal [ [ :grouped_light, "g1", { on: { on: false } } ] ], hue.writes
    targets = streams.map { |stream| stream["target"] }
    assert_includes targets, "room_head_r1"
    assert_includes targets, "house_summary"
    assert_equal [ "settle", "l1 l2" ], [ streams.last["action"], streams.last["light-ids"].split.sort.join(" ") ]
  end

  test "a room with a light another device is changing bounces whole" do
    claim = Hue::Locks.claim(%w[l2])
    patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    assert_response :conflict
    assert_empty hue.writes
    assert_select "turbo-stream[action=update][target=flash]", /Study is being changed from another device/
  ensure
    Hue::Locks.release(claim)
  end

  test "a room's brightness dims only the lights that are on" do
    patch room_path("r1"), params: { room: { brightness: "50" } }, as: :turbo_stream
    assert_response :accepted
    assert_equal [ [ :light, "l1", { on: { on: true }, dimming: { brightness: 50.0 } } ] ], hue.writes
    assert_equal [ "Study", "brightness 50%", "ok" ], [ Activity.last.target_name, Activity.last.action, Activity.last.result ]
  end

  test "a room that is all off turns on at the chosen brightness" do
    Hue::Light.where(id: %w[l1 l2]).update_all(on: false)
    patch room_path("r1"), params: { room: { brightness: "30" } }, as: :turbo_stream
    assert_equal [ [ :grouped_light, "g1", { on: { on: true }, dimming: { brightness: 30.0 } } ] ], hue.writes
  end

  test "a room's brightness bounces whole while any of its lights is being changed" do
    claim = Hue::Locks.claim(%w[l2])
    patch room_path("r1"), params: { room: { brightness: "50" } }, as: :turbo_stream
    assert_response :conflict
    assert_empty hue.writes
  ensure
    Hue::Locks.release(claim)
  end

  test "each room has a brightness slider at the average of its lit lights" do
    get root_path
    assert_select "#room_head_r1 form.room__dim[data-controller~=async-hue-call][data-controller~=room-brightness] input[type=range][name='room[brightness]'][value='80']"
    assert_select "#room_head_r1 form.room__dim output", "80%"
  end

  test "the slider greys out at the average when the lit lights are at different levels" do
    Hue::Light.find("l2").update!(on: true, brightness: 40)
    Hue::Device.find("d2").update!(reachable: true)
    get root_path
    assert_select "#room_head_r1 form.room__dim.is-mixed input[type=range][value='60']"
    assert_select "#room_head_r1 form.room__dim output", "~60%"
  end

  test "the slider is not grey when every lit light is at the same level" do
    get root_path
    assert_select "#room_head_r1 form.room__dim:not(.is-mixed)"
  end

  test "the room's power button and scene chips go through the async form controller with their lights" do
    get root_path
    assert_select "#room_head_r1 form.room__toggle[data-controller=async-hue-call][data-async-hue-call-light-ids-value*=l1]"
    assert_select "#room_r1 .scenes form.chip-form[data-controller=async-hue-call][data-async-hue-call-light-ids-value*=l2]"
    scene_targets = JSON.parse(css_select("#room_r1 .scenes form.chip-form[action$='s1/activate']").sole["data-async-hue-call-targets-value"])
    assert_equal %w[l1 l2], scene_targets.map { |target| target["light_id"] }.sort
  end

  test "recalls a scene" do
    post activate_scene_path("s1"), as: :turbo_stream
    assert_response :success
    assert_equal [ [ :scene, "s1", "active" ] ], hue.writes
    assert_equal "Relax in Study", Activity.last.target_name
  end
end

class RoomsOrderTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "arrange saves a shared order and ignores unknown ids" do
    patch order_rooms_path, params: { ids: %w[z1 bogus r1] }
    assert_response :no_content
    assert_equal [ [ "z1", 0 ], [ "r1", 1 ] ], HueExtensions::Group.order(:position).pluck(:id, :position)
    get root_path
    assert_select "main > section.room:first-of-type h2", /Evening/
  end
end
