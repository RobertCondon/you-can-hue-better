require "test_helper"

class Hue::Mirror::DeviceClassifierTest < ActiveSupport::TestCase
  test "names the kind of device from its product name" do
    assert_equal "bridge", Hue::Mirror::DeviceClassifier.kind_for("Hue Bridge", has_light: false)
    assert_equal "dial", Hue::Mirror::DeviceClassifier.kind_for("Hue tap dial switch", has_light: false)
    assert_equal "dimmer", Hue::Mirror::DeviceClassifier.kind_for("Hue dimmer switch", has_light: false)
    assert_equal "light", Hue::Mirror::DeviceClassifier.kind_for("Hue color lamp", has_light: true)
    assert_equal "other", Hue::Mirror::DeviceClassifier.kind_for("Hue motion sensor", has_light: false)
  end
end
