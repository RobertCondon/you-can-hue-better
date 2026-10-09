module HouseCommands
  module Dispatch
    LOG_PREFIX = "dispatch:"
    THREAD_NAME = "hue-command"

    module_function

    def later(claim, kind, &work)
      return run(claim, kind, &work) if inline?

      Thread.new { run(claim, kind, &work) }.tap { |thread| thread.name = THREAD_NAME }
    end

    def run(claim, kind, &work)
      Rails.application.reloader.wrap { Hue::CallTimings.measure(kind, &work) }
    rescue StandardError => error
      Rails.logger.error("#{LOG_PREFIX} #{kind} #{error.class}: #{error.message}")
    ensure
      Hue::Locks.release(claim)
      HouseBroadcast.settle(claim.light_ids)
    end

    def inline? = Rails.configuration.x.hue.dispatch_inline
  end
end
