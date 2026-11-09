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
    assert_equal [ "double", "r1", "off", "turn_on" ], [ rule.gesture, rule.if_group_id, rule.if_state, rule.action ]
    assert_equal [ "replace" ], streams.map { |stream| stream["action"] }
  end

  test "changes a rule" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_group_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { if_group_id: "r1", if_state: "on", action: "recall_scene" } }, as: :json

    assert_response :success
    assert_equal [ "r1", "on", "recall_scene", "s2" ], [ rule.reload.if_group_id, rule.if_state, rule.action, rule.scene_id ]
  end

  test "refuses an action it doesn't know" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_group_id: "r1")

    patch button_rule_path(rule), params: { button_rule: { action: "explode" } }, as: :json

    assert_response :unprocessable_entity
    assert_equal "turn_off", rule.reload.action
  end

  test "moves a rule up its list" do
    first = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_group_id: "r1")
    second = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_group_id: "r1")

    patch move_button_rule_path(second), params: { direction: "up" }, as: :json

    assert_response :no_content
    assert_equal [ second, first ], @button.reload.rules_for(ButtonRule::SINGLE)
  end

  test "refuses a direction it doesn't know" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_group_id: "r1")

    patch move_button_rule_path(rule), params: { direction: "sideways" }, as: :json

    assert_response :unprocessable_entity
  end

  test "removes a rule" do
    rule = @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_on", target_group_id: "r1")

    delete button_rule_path(rule), as: :json

    assert_response :no_content
    assert_not ButtonRule.exists?(rule.id)
  end
end
