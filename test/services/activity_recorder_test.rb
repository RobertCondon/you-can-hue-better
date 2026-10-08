require "test_helper"

class ActivityRecorderTest < ActiveSupport::TestCase
  def record(&command) = ActivityRecorder.record(target_kind: "light", target_id: "l1", target_name: "Desk lamp", action: "on", &command)

  test "logs a delivered command as ok and returns its result" do
    result = record { Hue::CommandResult.delivered }
    refute result.unreachable_lights?
    assert Activity.last.ok?
  end

  test "logs an unpowered bulb as not responding" do
    record { Hue::CommandResult.new(unreachable_lights: true) }
    assert Activity.last.unreachable?
  end

  test "logs a bridge error and raises it on" do
    assert_raises(Hue::Error) { record { raise Hue::Error, "link button not pressed" } }
    assert_equal "link button not pressed", Activity.last.result
  end
end
