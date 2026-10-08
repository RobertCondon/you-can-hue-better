class CustomScene < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group", optional: true
  belongs_to :hue_scene, class_name: "Hue::Scene", optional: true
  has_many :states, class_name: "CustomSceneState", dependent: :destroy
  has_many :lights, through: :states
  has_many :binding_steps, as: :scene, dependent: :destroy

  validates :name, presence: true
  validates :transition_ms, numericality: { greater_than_or_equal_to: 0 }

  def fits_one_group? = group.present? && (lights - group.lights).empty?
end
