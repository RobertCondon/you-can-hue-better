# Every press and turn the bridge reports, forever. Unique on the bridge's event id so a replay
# after reconnect is dropped rather than acted on twice.
class ControlEvent < ApplicationRecord
  belongs_to :control, class_name: "Hue::Control"
  belongs_to :control_binding, optional: true
  has_many :activities, dependent: :nullify

  validates :gesture, inclusion: { in: ControlBinding::GESTURES }
  validates :bridge_event_id, presence: true, uniqueness: { scope: :control_id }
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc).limit(50) }
end
