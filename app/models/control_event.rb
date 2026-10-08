class ControlEvent < ApplicationRecord
  RECENT_LIMIT = 50

  belongs_to :control, class_name: "Hue::Control"
  belongs_to :control_binding, optional: true
  has_many :activities, dependent: :nullify

  validates :gesture, inclusion: { in: ControlBinding::GESTURES }
  validates :bridge_event_id, presence: true, uniqueness: { scope: :control_id }
  validates :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc).limit(RECENT_LIMIT) }
end
