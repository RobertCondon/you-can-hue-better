class House
  class SceneTarget < Data.define(:light_id, :on, :level, :hex)
    def self.from_custom_scene_light(scene_light)
      new(light_id: scene_light.hue_light_id, on: scene_light.on, level: level_of(scene_light.brightness), hex: hex_of(scene_light))
    end

    def self.from_scene_action(action)
      new(light_id: action.light_id, on: action.on, level: level_of(action.brightness), hex: action.hex)
    end

    def self.level_of(brightness) = brightness && brightness.round.clamp(Hue::Api::Limits::LIT_BRIGHTNESS)

    def self.hex_of(scene_light)
      return Hue::Color.xy_to_hex(scene_light.color_x.to_f, scene_light.color_y.to_f) if scene_light.color_x && scene_light.color_y

      Hue::Color.mirek_to_hex(scene_light.mirek) if scene_light.mirek
    end
  end
end
