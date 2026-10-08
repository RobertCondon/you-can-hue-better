# Conversions between sRGB hex and the CIE 1931 xy space Hue uses.
# Based on Philips' published algorithm (wide RGB D65 matrix). Good enough for a colour picker.
module Hue
  module Color
    module_function

    def hex_to_xy(hex)
      r, g, b = hex_to_rgb(hex).map { |c| gamma_decode(c / 255.0) }
      x = r * 0.4124 + g * 0.3576 + b * 0.1805
      y = r * 0.2126 + g * 0.7152 + b * 0.0722
      z = r * 0.0193 + g * 0.1192 + b * 0.9505
      sum = x + y + z
      return { x: 0.3127, y: 0.3290 } if sum.zero?
      { x: (x / sum).round(4), y: (y / sum).round(4) }
    end

    # Returns a hex colour at full brightness for the given xy point.
    def xy_to_hex(x, y)
      return "#000000" if y.zero?
      yy = 1.0
      xx = (yy / y) * x
      zz = (yy / y) * (1 - x - y)
      r =  xx * 3.2406 - yy * 1.5372 - zz * 0.4986
      g = -xx * 0.9689 + yy * 1.8758 + zz * 0.0415
      b =  xx * 0.0557 - yy * 0.2040 + zz * 1.0570
      rgb = [ r, g, b ].map { |c| c.clamp(0, Float::INFINITY) }
      max = rgb.max
      rgb = rgb.map { |c| c / max } if max > 1
      rgb_to_hex(rgb.map { |c| (gamma_encode(c) * 255).round.clamp(0, 255) })
    end

    # Linear blend between two hex colours. t = 0 -> a, t = 1 -> b.
    def mix(a, b, t)
      ra, ga, ba = hex_to_rgb(a)
      rb, gb, bb = hex_to_rgb(b)
      rgb_to_hex([ ra + (rb - ra) * t, ga + (gb - ga) * t, ba + (bb - ba) * t ].map(&:round))
    end

    # Perceived luminance 0..1, for picking readable text on a tinted background.
    def luminance(hex)
      r, g, b = hex_to_rgb(hex).map { |c| gamma_decode(c / 255.0) }
      0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    # Approximate sRGB of a white at a colour temperature (mirek = 1e6 / kelvin). Same maths as the JS.
    def mirek_to_hex(mirek)
      t = 1_000_000.0 / mirek / 100
      r = t <= 66 ? 255 : 329.698727446 * ((t - 60)**-0.1332047592)
      g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * ((t - 60)**-0.0755148492)
      b = t >= 66 ? 255 : (t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307)
      rgb_to_hex([ r, g, b ].map { _1.round.clamp(0, 255) })
    end

    # 0..360, for sorting colours into a spectrum.
    def hue_angle(hex)
      r, g, b = hex_to_rgb(hex).map { _1 / 255.0 }
      max = [ r, g, b ].max; min = [ r, g, b ].min; d = max - min
      return 0.0 if d.zero?
      h = if max == r then 60 * (((g - b) / d) % 6)
          elsif max == g then 60 * ((b - r) / d + 2)
          else 60 * ((r - g) / d + 4)
          end
      h.negative? ? h + 360 : h
    end

    def hex_to_rgb(hex)
      hex = hex.delete_prefix("#")
      hex = hex.chars.map { |c| c * 2 }.join if hex.length == 3
      hex.scan(/../).map { |pair| pair.to_i(16) }
    end

    def rgb_to_hex(rgb)
      "#" + rgb.map { |c| format("%02x", c.clamp(0, 255)) }.join
    end

    def gamma_decode(c) = c > 0.04045 ? ((c + 0.055) / 1.055)**2.4 : c / 12.92
    def gamma_encode(c) = c <= 0.0031308 ? 12.92 * c : 1.055 * (c**(1 / 2.4)) - 0.055
  end
end
