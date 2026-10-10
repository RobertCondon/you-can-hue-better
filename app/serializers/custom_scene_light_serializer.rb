class CustomSceneLightSerializer
  include Alba::Resource

  attributes :id, :hue_light_id, :on, :mirek

  attribute(:brightness) { |light| light.brightness&.to_f }
  attribute(:color_x) { |light| light.color_x&.to_f }
  attribute(:color_y) { |light| light.color_y&.to_f }
end
