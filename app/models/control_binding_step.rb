# One entry in a binding's scene list. recall_scene has one; cycle_scenes has several.
class ControlBindingStep < ApplicationRecord
  belongs_to :control_binding
  belongs_to :scene, polymorphic: true   # Hue::Scene or CustomScene

  validates :position, numericality: { greater_than_or_equal_to: 0 }, uniqueness: { scope: :control_binding_id }
end
