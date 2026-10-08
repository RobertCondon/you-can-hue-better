module Hue
  # Keeps the mirror fresh. Runs in one background thread (see lib/puma/plugin/hue_listener.rb):
  # full sync on connect, then apply every event the bridge streams, heartbeat so the dashboard knows
  # the mirror is live, broadcast changes to open pages, reconnect with backoff when the stream drops.
  #
  # Presses from switches are logged (control_events) but not acted on. The bridge's own rules
  # still drive the switches and the dial.
  #
  # Dev-mode note: this object outlives code reloads, so every constant below is looked up from the
  # top level (::Hue::X) at call time rather than through this class's lexical scope, and any error
  # is rescued so the thread survives.
  class Listener
    def initialize(stop: -> { false }, logger: Rails.logger, sleeper: ->(s) { sleep s })
      @stop = stop
      @logger = logger
      @sleeper = sleeper
    end

    def run
      backoff = 1
      waiting = false
      until @stop.call
        begin
          unless with_app { ::Hue.configured? }
            @logger.info "hue-listener: no bridge yet; waiting for the setup page" unless waiting
            waiting = true
            @sleeper.call(3)
            next
          end
          if waiting
            with_app { ::Hue.reset! }     # the first client was built before there was a bridge
            waiting = false
          end
          with_app do
            ::Hue::Sync.run
            ::Hue::ListenerState.current.beat!
            ::HouseBroadcast.status
          end
          @logger.info "hue-listener: connected, mirror synced"
          backoff = 1
          ::Hue::EventStream.new.each(on_keepalive: -> { with_app { ::Hue::ListenerState.current.beat! } }) do |batch|
            with_app { handle(batch) }
            break if @stop.call
          end
        rescue Net::ReadTimeout
          @logger.info "hue-listener: quiet for a while, reconnecting"
        rescue StandardError => e
          @logger.warn "hue-listener: #{e.class}: #{e.message}; retrying in #{backoff}s"
          with_app { ::Hue::ListenerState.current.disconnected!; ::HouseBroadcast.status } rescue nil
          @sleeper.call(backoff)
          backoff = [ backoff * 2, 30 ].min
        end
      end
      with_app { ::Hue::ListenerState.current.disconnected!; ::HouseBroadcast.status } rescue nil
      @logger.info "hue-listener: stopped"
    end

    def handle(batch)
      changes = ::Hue::Mirror::Changes.none
      batch.each do |event|
        changes.merge!(::Hue::Mirror.apply(event["data"], event_id: event["id"], occurred_at: event["creationtime"], kind: event["type"]))
      end
      if changes.structural
        @logger.info "hue-listener: structural change, full sync"
        ::Hue::Sync.run
        ::HouseBroadcast.everything
      else
        ::HouseBroadcast.changes(changes)
      end
      last = batch.last
      ::Hue::ListenerState.current.beat!(event_id: last["id"], event_at: last["creationtime"])
    end

    private

    # Runs a block with the app's reloader and executor: dev code reloading stays correct and the
    # thread's database connection is returned afterwards.
    def with_app(&) = Rails.application.reloader.wrap(&)
  end
end
