require "test_helper"

class Hue::ColorTest < ActiveSupport::TestCase
  test "pure red lands near the red corner of the gamut" do
    xy = Hue::Color.hex_to_xy("#ff0000")
    assert_in_delta 0.64, xy[:x], 0.01
    assert_in_delta 0.33, xy[:y], 0.01
  end

  test "white lands on the D65 white point" do
    xy = Hue::Color.hex_to_xy("#ffffff")
    assert_in_delta 0.3127, xy[:x], 0.005
    assert_in_delta 0.3290, xy[:y], 0.005
  end

  test "black does not divide by zero" do
    assert_equal({ x: 0.3127, y: 0.3290 }, Hue::Color.hex_to_xy("#000000"))
  end

  test "xy round-trips a saturated colour closely" do
    xy = Hue::Color.hex_to_xy("#ff8800")
    back = Hue::Color.xy_to_hex(xy[:x], xy[:y])
    r, g, b = Hue::Color.hex_to_rgb(back)
    assert_equal 255, r
    assert_in_delta 136, g, 12
    assert_in_delta 0, b, 12
  end

  test "warm white from the bridge renders as amber" do
    assert_equal "#ffb05f", Hue::Color.xy_to_hex(0.4529, 0.4089)
  end

  test "mix interpolates channels" do
    assert_equal "#000000", Hue::Color.mix("#000000", "#ffffff", 0)
    assert_equal "#ffffff", Hue::Color.mix("#000000", "#ffffff", 1)
    assert_equal "#808080", Hue::Color.mix("#000000", "#ffffff", 0.5)
  end

  test "luminance separates light and dark" do
    assert Hue::Color.luminance("#ffffff") > 0.9
    assert Hue::Color.luminance("#000000") < 0.01
  end
end
