module Hue
  class Listener
    SETUP_POLL_SECONDS = 3
    LOG_PREFIX = "hue-listener:"

    def initialize(stop: -> { false }, logger: Rails.logger, sleeper: ->(seconds) { sleep seconds })
      @stop = stop
      @logger = logger
      @sleeper = sleeper
      @backoff = ::Hue::Listener::Backoff.new
      @waiting_for_setup = false
    end

    def run
      run_once until @stop.call
      mark_disconnected
      log "stopped"
    end

    private

    def run_once
      bridge_configured? ? connect_and_stream : wait_for_setup
    rescue Net::ReadTimeout
      log "quiet for a while, reconnecting"
    rescue StandardError => error
      log "#{error.class}: #{error.message}; retrying in #{@backoff.seconds}s", level: :warn
      mark_disconnected
      @sleeper.call(@backoff.seconds)
      @backoff.increase
    end

    def bridge_configured? = within_reloadable_app { ::Hue.configured? }

    def wait_for_setup
      log "no bridge yet; waiting for the setup page" unless @waiting_for_setup
      @waiting_for_setup = true
      @sleeper.call(SETUP_POLL_SECONDS)
    end

    def connect_and_stream
      synchronise
      log "connected, mirror synced"
      @backoff.reset
      ::Hue::EventStream.new.each_batch(on_keepalive: -> { heartbeat }) do |batch|
        within_reloadable_app { ::Hue::Listener::BatchHandler.new(logger: @logger).handle(batch) }
        break if @stop.call
      end
    end

    def synchronise
      within_reloadable_app do
        ::Hue.reset_client! if @waiting_for_setup
        @waiting_for_setup = false
        ::Hue::Sync.run
        ::Hue::ListenerState.current.beat!
        ::HouseBroadcast.listener_status
      end
    end

    def heartbeat = within_reloadable_app { ::Hue::ListenerState.current.beat! }

    def mark_disconnected
      within_reloadable_app do
        ::Hue::ListenerState.current.disconnected!
        ::HouseBroadcast.listener_status
      end
    rescue StandardError
      nil
    end

    def log(message, level: :info) = @logger.public_send(level, "#{LOG_PREFIX} #{message}")

    def within_reloadable_app(&) = Rails.application.reloader.wrap(&)
  end
end
