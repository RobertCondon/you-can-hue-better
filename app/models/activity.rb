class Activity < ApplicationRecord
  DASHBOARD = "dashboard"
  SOURCES = [ DASHBOARD, "remote", "schedule", "api" ].freeze
  OK = "ok"
  UNREACHABLE = "not responding"
  RECENT_LIMIT = 20

  belongs_to :control_event, optional: true

  validates :target_kind, :target_name, :action, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc).limit(RECENT_LIMIT) }

  def ok? = result == OK
  def unreachable? = result == UNREACHABLE
end
