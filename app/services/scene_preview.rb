module ScenePreview
  FULL_BRIGHTNESS = 100.0
  BRIGHTNESS_DECIMAL_PLACES = 2
  DARK = 0

  module_function

  def light_states(scene)
    scene.actions.map do |action|
      light = action.to_snapshot
      { light_id: action.light_id, on: light.lit?, hex: light.hex, bri: light.lit? ? (light.brightness / FULL_BRIGHTNESS).round(BRIGHTNESS_DECIMAL_PLACES) : DARK }
    end
  end
end
