require "test_helper"

class HouseLightReachableTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "a bulb the bridge cannot reach is not lit, whatever the bridge stored" do
    Hue::Device.find("d1").update!(reachable: false)
    l = House.load.light("l1")
    assert l.on?, "the bridge still says on"
    refute l.lit?
    assert_equal "Not responding", l.brightness_label
    assert_equal House::Light::OFF_TILE, l.tile_hex
    assert_equal 0, House.load.on_count
    assert_equal "All off", House.load.room("r1").summary
  end
end
