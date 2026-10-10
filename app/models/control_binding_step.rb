class ControlBindingStep < ApplicationRecord
  belongs_to :control_binding
  belongs_to :scene, polymorphic: true

  validates :position, numericality: { greater_than_or_equal_to: 0 }, uniqueness: { scope: :control_binding_id }
end

# == Schema Information
#
# Table name: control_binding_steps
#
#  id                 :integer          not null, primary key
#  position           :integer          not null
#  scene_type         :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  control_binding_id :integer          not null
#  scene_id           :string           not null
#
# Indexes
#
#  index_control_binding_steps_on_control_binding_id               (control_binding_id)
#  index_control_binding_steps_on_control_binding_id_and_position  (control_binding_id,position) UNIQUE
#
# Foreign Keys
#
#  control_binding_id  (control_binding_id => control_bindings.id)
#
