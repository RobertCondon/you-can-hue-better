module CustomSceneCapture
  module_function

  def call(name:, lights:, group: nil)
    CustomScene.create!(name:, group:) do |scene|
      lights.each do |light|
        scene.states.build(light:, on: light.on, brightness: light.brightness, color_x: light.color_x, color_y: light.color_y, mirek: light.mirek)
      end
    end
  end
end
