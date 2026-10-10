require "test_helper"

class HouseCommands::LightUpdateTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  def update_with(fields) = HouseCommands::LightUpdate.call(Hue::Light.find("l1"), ActionController::Parameters.new(fields).permit!)

  def sent_payload = hue.writes.last[2]

  test "power is sent exactly as asked" do
    update_with(on: "false")
    assert_equal [ { on: { on: false } }, "off" ], [ sent_payload, Activity.last.action ]
  end

  test "brightness never asks for less than the lowest step" do
    update_with(brightness: "0")
    assert_equal({ on: { on: true }, dimming: { brightness: 1.0 } }, sent_payload)
  end

  test "a white is kept within the bulb's range and described in kelvin" do
    update_with(mirek: "9000")
    assert_equal({ on: { on: true }, color_temperature: { mirek: 500 } }, sent_payload)
    assert_equal "white 2000K", Activity.last.action
  end

  test "a point on the colour wheel is kept inside the CIE square" do
    update_with(x: "1.4", y: "0.33333")
    assert_equal({ x: 1.0, y: 0.3333 }, sent_payload[:color][:xy])
  end

  test "nothing to change is an error the person sees" do
    assert_raises(HouseCommands::NothingToSend) { update_with({}) }
  end
end
