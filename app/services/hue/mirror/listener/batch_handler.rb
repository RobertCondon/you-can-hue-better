module Hue
  class Mirror
    class Listener
      class BatchHandler
        def initialize(logger:)
          @logger = logger
        end

        def handle(batch)
          changes = apply(batch)
          changes.full_sync_needed? ? resynchronise : HouseBroadcast.changes(changes)
          record_last_event(batch.last)
        end

        private

        def apply(batch)
          batch.each_with_object(Mirror::Changes.new) do |stream_event, changes|
            Mirror.apply(unlocked_resources_in(stream_event), event: Mirror::Event.from_stream(stream_event), changes:)
          end
        end

        def unlocked_resources_in(stream_event) = Mirror::Event.resources_in(stream_event).reject { |resource| LockedEcho.match?(resource) }

        def resynchronise
          @logger.info "#{Listener::LOG_PREFIX} structural change, full sync"
          Sync.call
          HouseBroadcast.everything
        end

        def record_last_event(stream_event)
          last_event = Mirror::Event.from_stream(stream_event)
          ListenerState.current.beat!(event_id: last_event.id, event_at: last_event.occurred_at)
        end
      end
    end
  end
end
