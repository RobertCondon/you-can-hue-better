require "test_helper"

class ButtonRuleTest < ActiveSupport::TestCase
  setup do
    sync_mirror!
    @button = LocalButton.create!(client: "hall-board", key: "button-1")
  end

  test "checking something starts it at on, and going back to always clears it" do
    checked = rule(if_subject_type: ButtonRule::LIGHT, if_subject_id: "l1", if_state: "")
    assert_equal ButtonRule::ON, checked.if_state

    checked.update!(if_subject_id: "")
    assert_equal [ nil, nil, nil ], [ checked.if_subject_type, checked.if_subject_id, checked.if_state ]
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

  test "setting a brightness starts at half, and other actions drop it" do
    dimmed = rule(action: ButtonRule::SET_BRIGHTNESS)
    assert_equal ButtonRule::DEFAULT_BRIGHTNESS, dimmed.brightness

    dimmed.update!(action: ButtonRule::TURN_ON)
    assert_nil dimmed.brightness
  end

  test "a scene can only be set in a room" do
    on_a_light = @button.rules.build(gesture: ButtonRule::SINGLE, action: ButtonRule::RECALL_SCENE, target_type: ButtonRule::LIGHT, target_id: "l1")

    assert_not on_a_light.valid?
    assert on_a_light.errors.added?(:base, :scene_needs_a_room)
  end

  test "refuses a scene action in a room with no scenes" do
    scened = @button.rules.build(gesture: ButtonRule::SINGLE, action: ButtonRule::RECALL_SCENE, target_type: ButtonRule::ROOM, target_id: "gone")

    assert_not scened.valid?
    assert scened.errors.added?(:scene_id, :blank)
  end

  test "new rules go to the bottom of their gesture's list" do
    first = rule
    second = rule
    double = rule(gesture: ButtonRule::DOUBLE)

    assert_equal [ 0, 1, 0 ], [ first, second, double ].map(&:position)
  end

  test "knows when something it uses has gone from the bridge" do
    assert rule(if_subject_type: ButtonRule::LIGHT, if_subject_id: "gone", if_state: "on").missing?
    assert rule(target_type: ButtonRule::LIGHT, target_id: "gone").missing?
    assert_not rule.missing?
  end

  private

  def rule(**attributes)
    @button.rules.create!({ gesture: ButtonRule::SINGLE, action: ButtonRule::TURN_OFF, target_type: ButtonRule::ROOM, target_id: "r1" }.merge(attributes))
  end
end
