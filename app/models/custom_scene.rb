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

# == Schema Information
#
# Table name: custom_scenes
#
#  id            :integer          not null, primary key
#  name          :string           not null
#  transition_ms :integer          default(400), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  group_id      :string
#  hue_scene_id  :string
#
# Indexes
#
#  index_custom_scenes_on_group_id      (group_id)
#  index_custom_scenes_on_hue_scene_id  (hue_scene_id)
#
# Foreign Keys
#
#  group_id      (group_id => hue_groups.id)
#  hue_scene_id  (hue_scene_id => hue_scenes.id)
#
