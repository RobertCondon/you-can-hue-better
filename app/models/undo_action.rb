class UndoAction < ApplicationRecord
  KEEP_FOR = 1.hour
  LIGHT_ID_KEY = "light_id"
  CHANGE_KEY = "change"

  LightState = Data.define(:light_id, :change)

  validates :description, presence: true

  scope :fresh, -> { where(created_at: KEEP_FOR.ago..) }
  scope :expired, -> { where(created_at: ..KEEP_FOR.ago) }

  def self.capture!(description, light_ids)
    expired.delete_all
    states = Hue::Light.where(id: light_ids).map { |light| { LIGHT_ID_KEY => light.id, CHANGE_KEY => light.current_change.to_h } }
    create!(description:, states:)
  end

  def light_states
    states.map { |state| LightState.new(light_id: state[LIGHT_ID_KEY], change: Hue::Api::LightChange.from_h(state[CHANGE_KEY])) }
  end

  def light_count = states.size
end
