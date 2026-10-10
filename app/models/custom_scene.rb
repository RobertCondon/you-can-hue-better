class CustomScene < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group", optional: true
  has_many :lights, class_name: "CustomSceneLight", dependent: :destroy
  has_many :hue_lights, through: :lights
  has_many :binding_steps, as: :scene, dependent: :destroy

  accepts_nested_attributes_for :lights, allow_destroy: true

  validates :name, presence: true
  validates :transition_ms, numericality: { greater_than_or_equal_to: 0 }
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
#
# Indexes
#
#  index_custom_scenes_on_group_id  (group_id)
#
# Foreign Keys
#
#  group_id  (group_id => hue_groups.id)
#
