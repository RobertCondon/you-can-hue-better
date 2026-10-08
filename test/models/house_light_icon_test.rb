require "test_helper"

class HouseLightIconTest < ActiveSupport::TestCase
  test "archetypes map to four glyphs, lamp by default" do
    assert_equal "candle", House::Light.new(id: "a", name: "a", on: true, brightness: 1, xy: nil, owner_id: nil, archetype: "candle_bulb").icon
    assert_equal "spot",   House::Light.new(id: "a", name: "a", on: true, brightness: 1, xy: nil, owner_id: nil, archetype: "spot_bulb").icon
    assert_equal "strip",  House::Light.new(id: "a", name: "a", on: true, brightness: 1, xy: nil, owner_id: nil, archetype: "hue_lightstrip").icon
    assert_equal "lamp",   House::Light.new(id: "a", name: "a", on: true, brightness: 1, xy: nil, owner_id: nil, archetype: "sultan_bulb").icon
    assert_equal "lamp",   House::Light.new(id: "a", name: "a", on: true, brightness: 1, xy: nil, owner_id: nil).icon
  end
end
