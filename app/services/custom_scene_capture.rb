class CustomSceneCapture
  def initialize(group)
    @group = group
  end

  def lights_attributes = @group.lights.includes(:device).map { |light| attributes_for(House::LightBuilder.from_mirror(light)) }

  private

  def attributes_for(light)
    colour = light.mirek_valid ? { mirek: light.mirek } : { color_x: light.xy&.dig(:x), color_y: light.xy&.dig(:y) }
    { hue_light_id: light.id, on: light.on, brightness: light.brightness, **colour }
  end
end
