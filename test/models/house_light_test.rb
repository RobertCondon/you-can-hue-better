require "test_helper"

class House::LightTest < ActiveSupport::TestCase
  test "an off light paints the off tile" do
    light = House::Light.from_api(Hue.client.lights.find("l2"))
    assert_equal House::Light::OFF_TILE, light.tile_hex
    assert_equal "Off", light.brightness_label
  end

  test "an on light paints its colour dimmed by brightness" do
    light = House::Light.from_api(Hue.client.lights.find("l1"))
    assert_equal "80%", light.brightness_label
    refute_equal House::Light::OFF_TILE, light.tile_hex
    assert_equal "#15181f", light.tile_text_hex, "amber at 80% is light enough for dark text"
  end
end

class HouseLightLevelTest < ActiveSupport::TestCase
  test "a bulb at Hue's lowest step reads 1%, not 0%" do
    l = House::Light.new(id: "a", name: "a", on: true, brightness: 0.39, xy: nil, owner_id: nil)
    assert_equal [ "1%", 1 ], [ l.brightness_label, l.fill_pct ]
    assert_equal [ "Off", 0 ], [ l.with(on: false).brightness_label, l.with(on: false).fill_pct ]
    assert_equal [ "80%", "80%" ], [ l.with(brightness: 79.6).brightness_label, l.with(brightness: 80.24).brightness_label ]
  end
end
