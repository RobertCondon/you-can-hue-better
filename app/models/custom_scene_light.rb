class CustomSceneLight < ApplicationRecord
  belongs_to :custom_scene
  belongs_to :hue_light, class_name: "Hue::Light", foreign_key: :light_id

  validates :brightness, numericality: { in: Hue::Api::Limits::BRIGHTNESS }, allow_nil: true
  validates :light_id, uniqueness: { scope: :custom_scene_id }
  validate :colour_or_mirek

  private

  def colour_or_mirek
    return if mirek.nil? || (color_x.nil? && color_y.nil?)

    errors.add(:base, "can have a colour or a mirek, not both")
  end
end

# == Schema Information
#
# Table name: custom_scene_lights
#
#  id              :integer          not null, primary key
#  brightness      :decimal(5, 2)
#  color_x         :decimal(6, 4)
#  color_y         :decimal(6, 4)
#  mirek           :integer
#  on              :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  custom_scene_id :integer          not null
#  light_id        :string           not null
#
# Indexes
#
#  index_custom_scene_lights_on_custom_scene_id               (custom_scene_id)
#  index_custom_scene_lights_on_custom_scene_id_and_light_id  (custom_scene_id,light_id) UNIQUE
#  index_custom_scene_lights_on_light_id                      (light_id)
#
# Foreign Keys
#
#  custom_scene_id  (custom_scene_id => custom_scenes.id)
#  light_id         (light_id => hue_lights.id)
#
