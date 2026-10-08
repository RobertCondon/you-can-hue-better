module Undo
  class LightState < Data.define(:light_id, :name, :on, :brightness, :color_x, :color_y, :mirek, :white)
    def self.of(light)
      new(
        light_id: light.id, name: light.name, on: light.on, brightness: light.brightness.to_f,
        color_x: light.color_x&.to_f, color_y: light.color_y&.to_f, mirek: light.mirek,
        white: Hue::Payloads::Light.new(light.raw).mirek_valid?
      )
    end

    def self.from_stored(stored_state) = new(**stored_state.symbolize_keys.slice(*members))

    def restoring_changes
      changes = { on: { on: } }
      return changes unless on

      changes[:dimming] = { brightness: } if brightness.to_f.positive?
      changes.merge(colour_changes)
    end

    private

    def colour_changes
      return { color_temperature: { mirek: } } if white && mirek
      return { color: { xy: { x: color_x, y: color_y } } } if color_x

      {}
    end
  end
end
