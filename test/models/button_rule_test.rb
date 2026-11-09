require "test_helper"

class ButtonRuleTest < ActiveSupport::TestCase
  setup do
    sync_mirror!
    @button = LocalButton.create!(client: "hall-board", key: "button-1")
  end

  test "a rule with no room to check always matches" do
    assert rule.matches?
  end

  test "a room counts as on when any of its lights is" do
    assert rule(if_group_id: "r1", if_state: "on").matches?
    assert_not rule(if_group_id: "r1", if_state: "off").matches?

    Hue::Light.update_all(on: false)

    assert rule(if_group_id: "r1", if_state: "off").matches?
  end

  test "picking a room to check starts it at on, and going back to always clears the state" do
    checked = rule(if_group_id: "r1", if_state: "")
    assert_equal ButtonRule::ON, checked.if_state

    checked.update!(if_group_id: "")
    assert_nil checked.if_group_id
    assert_nil checked.if_state
  end

  test "setting a scene picks one from the room being changed, and keeps one that belongs to it" do
    scened = rule
    scened.update!(action: ButtonRule::RECALL_SCENE)
    assert_equal "s2", scened.scene_id

    scened.update!(scene_id: "s1")
    assert_equal "s1", scened.scene_id

    scened.update!(scene_id: "s3")
    assert_equal "s2", scened.scene_id, "s3 belongs to another room"

    scened.update!(action: ButtonRule::TURN_ON)
    assert_nil scened.scene_id
  end

  test "refuses a scene action in a room with no scenes" do
    scened = @button.rules.build(gesture: ButtonRule::SINGLE, action: ButtonRule::RECALL_SCENE, target_group_id: "gone")

    assert_not scened.valid?
    assert scened.errors.added?(:scene_id, :blank)
  end

  test "new rules go to the bottom of their gesture's list" do
    first = rule
    second = rule
    double = rule(gesture: ButtonRule::DOUBLE)

    assert_equal [ 0, 1, 0 ], [ first, second, double ].map(&:position)
  end

  test "moves a rule up and down its list" do
    first = rule
    second = rule
    third = rule

    third.move!(ButtonRule::UP)
    assert_equal [ first, third, second ], @button.reload.rules_for(ButtonRule::SINGLE)

    first.move!(ButtonRule::UP)
    first.move!(ButtonRule::DOWN)
    assert_equal [ third, first, second ], @button.reload.rules_for(ButtonRule::SINGLE)
  end

  test "a rule whose room or scene has gone is skipped" do
    checks_gone = rule(if_group_id: "gone", if_state: "on")
    changes_gone = rule(target_group_id: "gone")

    assert checks_gone.missing?
    assert_not checks_gone.matches?
    assert changes_gone.missing?
    assert_nil LocalButtons::MatchingRule.call(@button.reload, ButtonRule::SINGLE)
  end

  test "Add a rule twice makes an on/off button for the first room" do
    first = @button.rules.create!(ButtonRule.starter(@button, ButtonRule::SINGLE))
    second = @button.reload.rules.create!(ButtonRule.starter(@button, ButtonRule::SINGLE))

    assert_equal [ "r1", "off", "turn_on", "r1" ], [ first.if_group_id, first.if_state, first.action, first.target_group_id ]
    assert_equal [ nil, nil, "turn_off", "r1" ], [ second.if_group_id, second.if_state, second.action, second.target_group_id ]
  end

  private

  def rule(**attributes)
    @button.rules.create!({ gesture: ButtonRule::SINGLE, action: ButtonRule::TURN_OFF, target_group_id: "r1" }.merge(attributes))
  end
end
