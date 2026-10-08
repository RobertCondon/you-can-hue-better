class Floor
  module ScenePreview
    module_function

    def light_states(scene)
      scene.actions.map do |action|
        light = House::LightBuilder.from_scene_action(action)
        { light_id: action.light_id, on: light.lit?, hex: light.hex, bri: light.glow }
      end
    end
  end
end
