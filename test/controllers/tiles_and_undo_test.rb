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

class UndoTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "turning a room off offers Undo, and Undo puts every light back" do
    patch room_path("r1"), params: { room: { on: "false" } }, as: :turbo_stream
    assert_response :success
    undo = UndoAction.last
    assert_equal "Study turned off", undo.description
    assert_equal 2, undo.light_count
    assert_equal [ true, 80.0 ], [ undo.light_states.find { |state| state.light_id == "l1" }.on, undo.light_states.find { |state| state.light_id == "l1" }.brightness ]
    assert_select "turbo-stream[action=update][target=flash] .flash--undo form[action='#{undo_path(undo)}'] button", "Undo"

    hue.writes.clear
    post undo_path(undo), as: :turbo_stream
    assert_response :success
    restored = hue.writes.find { |write| write.first == :light && write.second == "l1" }
    assert_equal({ on: { on: true }, dimming: { brightness: 80.0 }, color_temperature: { mirek: 359 } }, restored[2], "the fake's Desk lamp is in white mode, so it comes back as a temperature")
    assert_select "turbo-stream[action=update][target=flash] .flash--done", /Undone: Study turned off/
    refute UndoAction.exists?(undo.id)
    assert_equal "undo 2 lights", Activity.last.action
  end

  test "setting a scene offers Undo for just its lights" do
    post activate_scene_path("s3"), as: :turbo_stream
    undo = UndoAction.last
    assert_equal "Dusk set in Evening", undo.description
    assert_equal [ "l1" ], undo.light_states.map(&:light_id)
  end

  test "a white light is restored as a temperature, not a colour" do
    Hue::Light.find("l1").update!(raw: Hue::Light.find("l1").raw.deep_merge("color_temperature" => { "mirek_valid" => true }), mirek: 366)
    undo = Undo::Capture.call("test", %w[l1])
    Undo::Restore.new(undo).run
    assert_equal({ on: { on: true }, dimming: { brightness: 80.0 }, color_temperature: { mirek: 366 } }, hue.writes.last[2])
  end

  test "old undo rows are swept" do
    UndoAction.create!(description: "old", states: [], created_at: 2.hours.ago)
    Undo::Capture.call("new", %w[l1])
    assert_equal [ "new" ], UndoAction.pluck(:description)
  end
end
