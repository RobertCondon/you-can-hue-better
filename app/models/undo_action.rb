class UndoAction < ApplicationRecord
  KEEP_FOR = 1.hour

  validates :description, presence: true

  scope :fresh, -> { where(created_at: KEEP_FOR.ago..) }
  scope :expired, -> { where(created_at: ..KEEP_FOR.ago) }

  def light_states = states.map { |stored_state| Undo::LightState.from_stored(stored_state) }
  def light_count = states.size
end
