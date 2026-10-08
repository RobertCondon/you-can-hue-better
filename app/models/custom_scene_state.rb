class CustomSceneState < ApplicationRecord
  belongs_to :custom_scene
  belongs_to :light, class_name: "Hue::Light"

  validates :brightness, numericality: { in: Hue::Light::BRIGHTNESS_RANGE }, allow_nil: true
  validates :light_id, uniqueness: { scope: :custom_scene_id }
end
