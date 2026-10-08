require "test_helper"

class House::LightTest < ActiveSupport::TestCase
  def light(**attributes) = House::Light.new(id: "a", name: "a", on: true, brightness: 50, xy: nil, owner_id: nil, **attributes)

  test "an off light paints the off tile" do
    sync_mirror!
    Hue::Device.find("d2").update!(reachable: true)
    corner_lamp = House::LightBuilder.from_mirror(Hue::Light.find("l2"))
    assert_equal House::Glow::OFF_HEX, corner_lamp.tile_hex
    assert_equal "Off", corner_lamp.brightness_label
  end

  test "an on light paints its colour dimmed by brightness" do
    sync_mirror!
    desk_lamp = House::LightBuilder.from_mirror(Hue::Light.find("l1"))
    assert_equal "80%", desk_lamp.brightness_label
    refute_equal House::Glow::OFF_HEX, desk_lamp.tile_hex
    assert_equal House::LightTile::DARK_INK, desk_lamp.tile_text_hex, "amber at 80% is light enough for dark text"
  end

  test "a bulb at Hue's lowest step reads 1%, not 0%" do
    dimmest = light(brightness: 0.39)
    assert_equal [ "1%", 1 ], [ dimmest.brightness_label, dimmest.fill_pct ]
    assert_equal [ "Off", 0 ], [ dimmest.with(on: false).brightness_label, dimmest.with(on: false).fill_pct ]
    assert_equal [ "80%", "80%" ], [ light(brightness: 79.6).brightness_label, light(brightness: 80.24).brightness_label ]
  end

  test "archetypes map to four glyphs, lamp by default, and an override wins" do
    assert_equal "candle", light(archetype: "candle_bulb").icon
    assert_equal "spot", light(archetype: "spot_bulb").icon
    assert_equal "strip", light(archetype: "hue_lightstrip").icon
    assert_equal "lamp", light(archetype: "sultan_bulb").icon
    assert_equal "lamp", light.icon
    assert_equal "strip", light(archetype: "candle_bulb", icon_override: "strip").icon
  end

  test "inks follow what sits under the label" do
    bright = light(brightness: 95, xy: { x: 0.45, y: 0.41 })
    dim = bright.with(brightness: 10)
    assert_equal bright.tile_text_hex, bright.name_ink, "name sits on a wide pale fill"
    assert_equal bright.tile_text_hex, bright.level_ink
    assert_equal House::LightTile::LIGHT_INK, dim.name_ink, "name sits on the dark tint"
    assert_equal House::LightTile::LIGHT_INK, dim.level_ink
  end

  test "a bulb the bridge cannot reach is not lit, whatever the bridge stored" do
    sync_mirror!
    Hue::Device.find("d1").update!(reachable: false)
    house = House.load
    desk_lamp = house.light("l1")
    assert desk_lamp.on?, "the bridge still says on"
    refute desk_lamp.lit?
    assert_equal "Not responding", desk_lamp.brightness_label
    assert_equal House::Glow::OFF_HEX, desk_lamp.tile_hex
    assert_equal 0, house.on_count
    assert_equal "All off", house.room("r1").summary
  end
end
