require "test_helper"

class TileGrammarTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "a tile has an icon that switches, a name that opens, and a fill for the level" do
    get root_path
    assert_select "#light_r1_l1[data-controller=tile][data-tile-url-value='#{light_path("l1")}'][style*='--fill: 80%']"
    assert_select "#light_r1_l1 .tile__icon[data-action='tile#toggle'][aria-pressed=true] svg.ico"
    assert_select "#light_r1_l1 .tile__open[data-action='light-panel#toggle'] .tile__name", "Desk lamp"
    assert_select "#light_r1_l1 .tile__fill"
    assert_select "#light_r1_l2.is-off[style*='--fill: 0%']"
  end
end

class RoomSwitchToastTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "switching a room off clears the toast and asks nothing more" do
    patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action=update][target=flash] template", text: ""
    assert_equal "off", Activity.last.action
  end
end
