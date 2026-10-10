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

# == Schema Information
#
# Table name: control_events
#
#  id                 :integer          not null, primary key
#  duration_ms        :integer
#  gesture            :string           not null
#  occurred_at        :datetime         not null
#  rotation_direction :string
#  rotation_steps     :integer
#  created_at         :datetime         not null
#  bridge_event_id    :string           not null
#  control_binding_id :integer
#  control_id         :string           not null
#
# Indexes
#
#  index_control_events_on_bridge_event_id_and_control_id  (bridge_event_id,control_id) UNIQUE
#  index_control_events_on_control_binding_id              (control_binding_id)
#  index_control_events_on_control_id                      (control_id)
#  index_control_events_on_occurred_at                     (occurred_at)
#
# Foreign Keys
#
#  control_binding_id  (control_binding_id => control_bindings.id)
#  control_id          (control_id => hue_controls.id)
#
