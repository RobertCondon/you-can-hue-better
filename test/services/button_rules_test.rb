require "test_helper"

# Study (r1) holds Desk lamp (l1, on) and Corner lamp (l2, off).
class ButtonRulesTest < ActiveSupport::TestCase
  setup do
    sync_mirror!
    @button = LocalButton.create!(client: "hall-board", key: "button-1")
  end

  test "Lit: a light by its own state, a room when any of its lights is on" do
    assert ButtonRules::Lit.call(Hue::Light.find("l1"))
    assert_not ButtonRules::Lit.call(Hue::Light.find("l2"))
    assert ButtonRules::Lit.call(Hue::Group.find("r1"))

    Hue::Light.update_all(on: false)

    assert_not ButtonRules::Lit.call(Hue::Group.find("r1"))
  end

  test "Condition: always matches when it checks nothing" do
    assert ButtonRules::Condition.call(rule)
  end

  test "Condition: checks a room or a single light against its state" do
    assert ButtonRules::Condition.call(rule(if_subject_type: ButtonRule::ROOM, if_subject_id: "r1", if_state: "on"))
    assert ButtonRules::Condition.call(rule(if_subject_type: ButtonRule::LIGHT, if_subject_id: "l2", if_state: "off"))
    assert_not ButtonRules::Condition.call(rule(if_subject_type: ButtonRule::LIGHT, if_subject_id: "l1", if_state: "off"))
  end

  test "Condition: false when what it checks or changes has gone" do
    assert_not ButtonRules::Condition.call(rule(if_subject_type: ButtonRule::LIGHT, if_subject_id: "gone", if_state: "on"))
    assert_not ButtonRules::Condition.call(rule(target_type: ButtonRule::LIGHT, target_id: "gone"))
  end

  test "Command: a room's switch and brightness use the room commands" do
    assert_instance_of HouseCommands::RoomSwitch, ButtonRules::Command.call(rule)
    assert_instance_of HouseCommands::RoomBrightness, ButtonRules::Command.call(rule(action: ButtonRule::SET_BRIGHTNESS))
  end

  test "Command: a single light uses the light command" do
    assert_instance_of HouseCommands::LightUpdate, ButtonRules::Command.call(rule(target_type: ButtonRule::LIGHT, target_id: "l1", action: ButtonRule::TOGGLE))
  end

  test "Move: swaps a rule with its neighbour and ignores moves off the end" do
    first = rule
    second = rule
    third = rule

    ButtonRules::Move.call(third, ButtonRule::UP)
    assert_equal [ first, third, second ], @button.reload.rules_for(ButtonRule::SINGLE)

    ButtonRules::Move.call(first, ButtonRule::UP)
    ButtonRules::Move.call(first, ButtonRule::DOWN)
    assert_equal [ third, first, second ], @button.reload.rules_for(ButtonRule::SINGLE)
  end

  test "Starter: Add a rule twice makes an on/off button for the first room" do
    first = @button.rules.create!(ButtonRules::Starter.call(@button, ButtonRule::SINGLE))
    second = @button.reload.rules.create!(ButtonRules::Starter.call(@button, ButtonRule::SINGLE))

    assert_equal [ "r1", "off", "turn_on", "r1" ], [ first.if_subject_id, first.if_state, first.action, first.target_id ]
    assert_equal [ nil, nil, "turn_off", "r1" ], [ second.if_subject_id, second.if_state, second.action, second.target_id ]
  end

  test "Fields: menu keys become type and id columns, other fields pass through" do
    fields = ButtonRules::Fields.call(if_subject: "light:l1", target: "room:r1", action: "toggle", brightness: "40")

    assert_equal({ if_subject_type: "Hue::Light", if_subject_id: "l1", target_type: "Hue::Group", target_id: "r1", action: "toggle", brightness: "40" }, fields)
  end

  test "Fields: always and unknown keys clear the columns" do
    assert_equal({ if_subject_type: nil, if_subject_id: nil }, ButtonRules::Fields.call(if_subject: ""))
    assert_equal({ target_type: nil, target_id: nil }, ButtonRules::Fields.call(target: "garage:g9"))
  end

  test "Choices: rooms and lights for the menus, rooms only for scenes" do
    choices = ButtonRules::Choices.call

    assert_includes choices.rooms, [ "Study", "room:r1" ]
    assert_includes choices.lights, [ "Desk lamp", "light:l1" ]
    assert_equal [ "Rooms", "Lights" ], choices.subjects.keys
    assert_equal [ "Rooms" ], choices.subjects(rooms_only: true).keys
  end

  private

  def rule(**attributes)
    @button.rules.create!({ gesture: ButtonRule::SINGLE, action: ButtonRule::TURN_OFF, target_type: ButtonRule::ROOM, target_id: "r1" }.merge(attributes))
  end
end
