class CustomScene < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group", optional: true
  belongs_to :hue_scene, class_name: "Hue::Scene", optional: true
  has_many :states, class_name: "CustomSceneState", dependent: :destroy
  has_many :lights, through: :states
  has_many :binding_steps, as: :scene, dependent: :destroy

  validates :name, presence: true
  validates :transition_ms, numericality: { greater_than_or_equal_to: 0 }

  def self.capture!(name:, lights:, group: nil)
    create!(name:, group:) do |scene|
      lights.each do |light|
        scene.states.build(light:, on: light.on, brightness: light.brightness, color_x: light.color_x, color_y: light.color_y, mirek: light.mirek)
      end
    end
  end

  def fits_one_group? = group.present? && (lights - group.lights).empty?
end
