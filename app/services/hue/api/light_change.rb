module Hue
  module Api
    class LightChange < Data.define(:on, :brightness, :xy, :mirek)
      ON = "on"
      OFF = "off"
      MIREKS_PER_KELVIN_RECIPROCAL = 1_000_000
      KELVIN_ROUNDING = -2

      def self.power(on) = new(on:)
      def self.brightness(level) = lit(brightness: level.to_f.clamp(Limits::LIT_BRIGHTNESS))
      def self.colour(hex) = lit(xy: Color.hex_to_xy(hex))
      def self.chromaticity(x, y) = lit(xy: { x: cie(x), y: cie(y) })
      def self.white(mirek) = lit(mirek: mirek.to_i.clamp(Limits::MIREK))
      def self.lit(**fields) = new(on: true, **fields)
      def self.cie(value) = value.to_f.clamp(Limits::CIE).round(Color::Cie::XY_DECIMAL_PLACES)

      def self.from_h(stored)
        fields = stored.to_h.symbolize_keys.slice(*members)
        new(**fields, xy: fields[:xy]&.symbolize_keys)
      end

      def initialize(on:, brightness: nil, xy: nil, mirek: nil) = super

      def to_payload
        payload = { on: { on: } }
        payload[:dimming] = { brightness: } if brightness
        payload[:color] = { xy: } if xy
        payload[:color_temperature] = { mirek: } if mirek
        payload
      end

      def description
        return "colour #{Color.xy_to_hex(xy[:x], xy[:y])}" if xy
        return "white #{kelvin}K" if mirek
        return "brightness #{brightness.round}%" if brightness

        on ? ON : OFF
      end

      private

      def kelvin = (MIREKS_PER_KELVIN_RECIPROCAL / mirek).round(KELVIN_ROUNDING)
    end
  end
end
