module ScenePreview
  module_function

  def light_states(scene)
    scene.actions.map do |action|
      light = action.to_snapshot
      { light_id: action.light_id, on: light.lit?, hex: light.hex, bri: light.glow }
    end
  end
end
