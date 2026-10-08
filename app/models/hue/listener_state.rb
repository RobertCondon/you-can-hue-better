module Hue
  class ListenerState < Record
    HEARTBEAT_EVERY = 20.seconds
    MISSED_HEARTBEATS_BEFORE_STALE = 3
    LIVENESS_WINDOW = HEARTBEAT_EVERY * MISSED_HEARTBEATS_BEFORE_STALE

    def self.current = first || create!

    def live? = heartbeat_at.present? && heartbeat_at > LIVENESS_WINDOW.ago
    def stale? = !live?

    def beat!(event_id: nil, event_at: nil)
      columns = { heartbeat_at: Time.current }
      columns.merge!(last_event_id: event_id, last_event_at: event_at) if event_id
      update_columns(columns)
    end

    def disconnected! = update_columns(heartbeat_at: nil)

    def mirror_current_as_of = [ last_event_at, full_sync_at ].compact.max
  end
end
