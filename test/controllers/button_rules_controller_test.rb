require "test_helper"
require "turbo/broadcastable/test_helper"

class ButtonRulesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    sync_mirror!
    @button = LocalButton.create!(client: "hall-board", key: "button-1")
  end

  test "adds a starter rule to a gesture and updates open pages" do
    streams = capture_turbo_stream_broadcasts(LocalButtons::Broadcast::STREAM) do
      post local_button_button_rules_path(@button), params: { button_rule: { gesture: "double" } }, as: :json
    end

    assert_response :created
    rule = @button.rules.sole
    assert_equal [ "double", "r1", "off", "turn_on" ], [ rule.gesture, rule.if_subject_id, rule.if_state, rule.action ]
    assert_equal [ "replace" ], streams.map { |stream| stream["action"] }
  end

  test "changes a rule" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_type: "Hue::Group", target_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { if_subject: "room:r1", if_state: "on", action: "recall_scene" } }, as: :json

    assert_response :success
    assert_equal [ "Hue::Group", "r1", "on", "recall_scene", "s2" ], [ rule.reload.if_subject_type, rule.if_subject_id, rule.if_state, rule.action, rule.scene_id ]
  end

  test "points a rule at a single light and sets its brightness" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_type: "Hue::Group", target_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { if_subject: "light:l1", action: "set_brightness", target: "light:l2", brightness: "30" } }, as: :json

    assert_response :success
    rule.reload
    assert_equal [ "Hue::Light", "l1", "Hue::Light", "l2", 30 ], [ rule.if_subject_type, rule.if_subject_id, rule.target_type, rule.target_id, rule.brightness ]
  end

  test "choosing always clears what the rule checked" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, if_subject_type: "Hue::Light", if_subject_id: "l1", action: "turn_off", target_type: "Hue::Group", target_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { if_subject: "" } }, as: :json

    assert_equal [ nil, nil, nil ], [ rule.reload.if_subject_type, rule.if_subject_id, rule.if_state ]
  end

  test "refuses a scene for a single light" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_type: "Hue::Light", target_id: "l1")

    patch button_rule_path(rule), params: { button_rule: { action: "recall_scene" } }, as: :json

    assert_response :unprocessable_entity
    assert_match(/only be set in a room/, response.parsed_body["error"])
  end

  test "refuses a brightness outside 1 to 100" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "set_brightness", target_type: "Hue::Light", target_id: "l1")

    patch button_rule_path(rule), params: { button_rule: { brightness: "140" } }, as: :json

    assert_response :unprocessable_entity
    assert_equal ButtonRule::DEFAULT_BRIGHTNESS, rule.reload.brightness
  end

  test "refuses an action it doesn't know" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_type: "Hue::Group", target_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { action: "explode" } }, as: :json

    assert_response :unprocessable_entity
    assert_equal "turn_off", rule.reload.action
  end

  test "moves a rule up its list" do
    first = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_type: "Hue::Group", target_id: "r1")
    second = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_type: "Hue::Group", target_id: "r1")

    patch move_button_rule_path(second), params: { direction: "up" }, as: :json

    assert_response :no_content
    assert_equal [ second, first ], @button.reload.rules_for(ButtonRule::SINGLE)
  end

  test "refuses a direction it doesn't know" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_type: "Hue::Group", target_id: "r1")

    patch move_button_rule_path(rule), params: { direction: "sideways" }, as: :json

    assert_response :unprocessable_entity
  end

  test "removes a rule" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_type: "Hue::Group", target_id: "r1")

    delete button_rule_path(rule), as: :json

    assert_response :no_content
    assert_not ButtonRule.exists?(rule.id)
  end
end
