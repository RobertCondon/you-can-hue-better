require "test_helper"
require "turbo/broadcastable/test_helper"

class ScenesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  setup { sync_mirror! }

  test "the scenes page lists cards per room with a dot per light" do
    get scenes_path
    assert_response :success
    assert_select "section.room", 2
    assert_select "#scene_card_s1 .scene-card__name", "Relax"
    assert_select "#scene_card_s1 .dot", 2
    assert_select "#scene_card_s1 form[action='#{play_scene_path("s1")}']", 1, "a scene with a palette can play"
    assert_select "#scene_card_s2 form[action='#{play_scene_path("s2")}']", 0
    assert_select "#scene_card_s1 small", /also in Evening/
  end

  test "a scene page draws the house floor as the scene would set it" do
    get scene_path("s1")
    assert_response :success
    assert_select "h1", "Relax"
    assert_select ".floor .floor__lamp.is-on[style*='--bri: 0.38']", 1
    assert_select "#floor_light_l2.is-unreachable", 1, "a bulb with no power can't show the scene"
    assert_select ".floor-head", 0, "no editing on a scene's floor"
    assert_select ".tiles .tile__level", "38%"
  end

  test "lights a scene does not set are greyed out, not hidden" do
    get scene_path("s3")
    assert_select ".floor .floor__lamp", 2
    assert_select "#floor_light_l1.is-on:not(.is-muted)"
    assert_select "#floor_light_l2.is-muted[aria-label*='not in this scene']"
  end

  test "play recalls the palette and refreshes the card" do
    streams = capture_turbo_stream_broadcasts(HouseBroadcast::STREAM) { post play_scene_path("s1"), as: :turbo_stream }
    assert_response :accepted
    assert_equal [ [ :scene, "s1", "dynamic_palette" ] ], hue.writes
    assert_includes streams.map { |stream| stream["target"] }, "scene_card_s1"
    assert_equal [ "play", "ok" ], [ Activity.last.action, Activity.last.result ]
  end

  test "a nickname shows on the card" do
    HueExtensions::Scene.create!(id: "s1", nickname: "Chill")
    get scenes_path
    assert_select "#scene_card_s1 .scene-card__name", "Chill"
  end
end
