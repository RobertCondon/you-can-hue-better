require "test_helper"

class HueExtensions::LightTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "visibility settings change only what is given, and a blank icon goes back to automatic" do
    HueExtensions::Light.set_visibility!("l1", "hidden" => "true")
    HueExtensions::Light.set_visibility!("l1", "icon" => "candle")
    extension = HueExtensions::Light.find("l1")
    assert_equal [ true, true, "candle" ], [ extension.hidden, extension.on_floor, extension.icon ]

    HueExtensions::Light.set_visibility!("l1", "on_floor" => "false", "icon" => "")
    assert_equal [ true, false, nil ], extension.reload.then { |reloaded| [ reloaded.hidden, reloaded.on_floor, reloaded.icon ] }
  end
end
