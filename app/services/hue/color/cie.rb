module Hue
  module Color
    module Cie
      RGB_TO_XYZ = [
        [ 0.4124, 0.3576, 0.1805 ],
        [ 0.2126, 0.7152, 0.0722 ],
        [ 0.0193, 0.1192, 0.9505 ]
      ].freeze
      XYZ_TO_RGB = [
        [ 3.2406, -1.5372, -0.4986 ],
        [ -0.9689, 1.8758, 0.0415 ],
        [ 0.0557, -0.2040, 1.0570 ]
      ].freeze
      D65_WHITE_POINT = { x: 0.3127, y: 0.3290 }.freeze
      XY_DECIMAL_PLACES = 4
      FULL_BRIGHTNESS = 1.0
      NO_LIGHT = 0.0

      module_function

      def xy_from_linear_rgb(linear_rgb)
        tristimulus_x, tristimulus_y, tristimulus_z = multiply(RGB_TO_XYZ, linear_rgb)
        total = tristimulus_x + tristimulus_y + tristimulus_z
        return D65_WHITE_POINT.dup if total.zero?

        { x: (tristimulus_x / total).round(XY_DECIMAL_PLACES), y: (tristimulus_y / total).round(XY_DECIMAL_PLACES) }
      end

      def linear_rgb_at_full_brightness(cie_x, cie_y)
        tristimulus = [
          FULL_BRIGHTNESS / cie_y * cie_x,
          FULL_BRIGHTNESS,
          FULL_BRIGHTNESS / cie_y * (1 - cie_x - cie_y)
        ]
        linear_rgb = multiply(XYZ_TO_RGB, tristimulus).map { |channel| [ channel, NO_LIGHT ].max }
        brightest = linear_rgb.max
        brightest > FULL_BRIGHTNESS ? linear_rgb.map { |channel| channel / brightest } : linear_rgb
      end

      def luminance(linear_rgb)
        _tristimulus_x, tristimulus_y, _tristimulus_z = multiply(RGB_TO_XYZ, linear_rgb)
        tristimulus_y
      end

      def multiply(matrix, vector)
        matrix.map { |row| row.zip(vector).sum { |coefficient, component| coefficient * component } }
      end
    end
  end
end
