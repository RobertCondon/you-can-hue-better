require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "turns a whole room off via its grouped light" do
    patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    assert_response :success
    assert_equal [ [ :grouped_light, "g1", { on: { on: false } } ] ], hue.writes
    assert_select "turbo-stream[action=replace][target=room_r1]"
    assert_select "turbo-stream[action=update][target=house_summary]"
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
