require "test_helper"

class Hue::ColorTest < ActiveSupport::TestCase
  SAMPLE_PATTERN = /\A(?<function>\S+) (?<arguments>.+)\z/
  ARGUMENT_SEPARATOR = /[ ,]/

  test "pure red lands near the red corner of the gamut" do
    chromaticity = Hue::Color.hex_to_xy("#ff0000")
    assert_in_delta 0.64, chromaticity[:x], 0.01
    assert_in_delta 0.33, chromaticity[:y], 0.01
  end

  test "black does not divide by zero" do
    assert_equal({ x: 0.3127, y: 0.3290 }, Hue::Color.hex_to_xy("#000000"))
  end

  test "xy round-trips a saturated colour closely" do
    chromaticity = Hue::Color.hex_to_xy("#ff8800")
    red, green, blue = Hue::Color::Srgb.channels_from_hex(Hue::Color.xy_to_hex(chromaticity[:x], chromaticity[:y]))
    assert_equal 255, red
    assert_in_delta 136, green, 12
    assert_in_delta 0, blue, 12
  end

  test "every conversion matches the values recorded before the refactor" do
    JSON.parse(file_fixture("color_baseline.json").read).each do |sample, expected|
      match = SAMPLE_PATTERN.match(sample)
      actual = convert(match[:function], match[:arguments].split(ARGUMENT_SEPARATOR))
      assert_equal normalise(expected), normalise(actual), sample
    end
  end

  private

  def convert(function, arguments)
    case function
    when "hex_to_xy" then Hue::Color.hex_to_xy(arguments.first)
    when "lum" then Hue::Color.luminance(arguments.first).round(10)
    when "angle" then Hue::Color.hue_angle(arguments.first).round(10)
    when "xy_to_hex" then Hue::Color.xy_to_hex(*arguments.map(&:to_f))
    when "mirek" then Hue::Color.mirek_to_hex(arguments.first.to_i)
    when "mix" then Hue::Color.mix(arguments[0], arguments[1], arguments[2].to_f)
    end
  end

  def normalise(value) = value.is_a?(Hash) ? value.transform_keys(&:to_s) : value
end
