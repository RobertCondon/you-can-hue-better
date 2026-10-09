class Activity < ApplicationRecord
  DASHBOARD = "dashboard"
  SOURCES = [ DASHBOARD, "remote", "schedule", "api" ].freeze
  OK = "ok"
  UNREACHABLE = "not responding"
  PENDING = "pending"
  INTERRUPTED = "cut short by a restart"
  RECENT_LIMIT = 20

  belongs_to :control_event, optional: true

  validates :target_kind, :target_name, :action, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc).limit(RECENT_LIMIT) }
  scope :pending, -> { where(result: PENDING) }

  def self.interrupt_pending! = pending.find_each { |activity| activity.settle!(INTERRUPTED) }

  def ok? = result == OK
  def unreachable? = result == UNREACHABLE
  def pending? = result == PENDING

  def settle!(outcome) = update!(result: outcome)
end
