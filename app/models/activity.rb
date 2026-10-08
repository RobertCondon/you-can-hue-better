# One row per command the app sends to the bridge.
class Activity < ApplicationRecord
  SOURCES = %w[dashboard remote schedule api].freeze

  belongs_to :control_event, optional: true

  validates :target_kind, :target_name, :action, presence: true
  validates :source, inclusion: { in: SOURCES }

  scope :recent, -> { order(created_at: :desc).limit(20) }

  UNREACHABLE = "not responding".freeze

  # Runs the block, logs the outcome, and returns the bridge response.
  # Raises the Hue::Error after logging it so the controller can show it.
  def self.record(target_kind:, target_id:, target_name:, action:, payload: {}, source: "dashboard", control_event: nil)
    response = yield
    result = response.is_a?(Hash) && response["unreachable"] ? UNREACHABLE : "ok"
    create!(target_kind:, target_id:, target_name:, action:, payload:, result:, source:, control_event:)
    response
  rescue Hue::Error => e
    create!(target_kind:, target_id:, target_name:, action:, payload:, result: e.message, source:, control_event:)
    raise
  end

  def ok?          = result == "ok"
  def unreachable? = result == UNREACHABLE
end
