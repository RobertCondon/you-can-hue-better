class ControlBindingStep < ApplicationRecord
  belongs_to :control_binding
  belongs_to :scene, polymorphic: true

  validates :position, numericality: { greater_than_or_equal_to: 0 }, uniqueness: { scope: :control_binding_id }
end
