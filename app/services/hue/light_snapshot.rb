module Hue
  module LightSnapshot
    module_function

    def from_light(light)
      payload = Payloads::Light.new(light.raw)
      extension = light.extension
      House::Light.new(
        **shared_attributes(light, payload),
        on: light.on, brightness: light.brightness.to_f, xy: light.xy,
        mirek: light.mirek, mirek_valid: payload.mirek_valid?,
        hidden: extension&.hidden, on_floor: extension.nil? || extension.on_floor, icon_override: extension&.icon
      )
    end

    def from_scene_action(action)
      light = action.light
      House::Light.new(
        **shared_attributes(light, Payloads::Light.new(light.raw)),
        on: action.on, brightness: action.brightness.to_f, xy: action.xy || action.white_xy,
        mirek: action.mirek, mirek_valid: action.white?
      )
    end

    def shared_attributes(light, payload)
      {
        id: light.id, name: light.name, owner_id: light.device_id, gamut: payload.gamut,
        nickname: light.extension&.nickname, reachable: light.device.reachable,
        archetype: payload.archetype || Payloads::Device.new(light.device.raw).product_archetype
      }
    end
  end
end
