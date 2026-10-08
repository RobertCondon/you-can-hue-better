require "test_helper"

class LightCommandTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  def command_for(fields) = LightCommand.new(Hue::Light.find("l1"), ActionController::Parameters.new(fields).permit!).command

  test "toggle switches to the opposite of what the bridge reports" do
    assert_equal [ { on: { on: false } }, "off" ], command_for(on: "toggle").then { |command| [ command.changes, command.description ] }
  end

  test "brightness never asks for less than the lowest step" do
    assert_equal({ on: { on: true }, dimming: { brightness: 1.0 } }, command_for(brightness: "0").changes)
  end

  test "a white is kept within the bulb's range and described in kelvin" do
    command = command_for(mirek: "9000")
    assert_equal({ on: { on: true }, color_temperature: { mirek: 500 } }, command.changes)
    assert_equal "white 2000K", command.description
  end

  test "a point on the colour wheel is kept inside the CIE square" do
    assert_equal({ x: 1.0, y: 0.3333 }, command_for(x: "1.4", y: "0.33333").changes[:color][:xy])
  end

  test "nothing to change is an error the person sees" do
    assert_raises(Hue::Error) { command_for({}) }
  end
end
