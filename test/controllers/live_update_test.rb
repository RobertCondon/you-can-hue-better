require "test_helper"
require "turbo/broadcastable/test_helper"

class LiveUpdateTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  setup { sync_mirror! }

  test "changing a light broadcasts its tile, pin, panel and floor lamp to the house stream" do
    streams = capture_turbo_stream_broadcasts("house") do
      patch light_path("l1"), params: { light: { brightness: "42" } }, as: :turbo_stream
    end
    targets = streams.map { |stream| stream["target"] }
    assert_includes targets, "light_r1_l1"
    assert_includes targets, "floor_light_l1"
    assert_includes targets, "light_pin_l1"
    assert_includes targets, "room_head_r1"
  end

  test "a room action broadcasts too" do
    streams = capture_turbo_stream_broadcasts("house") do
      patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    end
    assert_includes streams.map { |stream| stream["target"] }, "floor_light_l1"
  end
end
