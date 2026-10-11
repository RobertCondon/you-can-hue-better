module HouseCommands
  module Dispatch
    LOG_PREFIX = "dispatch:"
    THREAD_NAME = "hue-command"

    module_function

    def later(claim, kind, &work)
      return run(claim, kind, &work) if inline?

      Thread.new { run(claim, kind, &work) }.tap { |thread| thread.name = THREAD_NAME }
    end

    # The work is handed a way to free the lights as soon as the bridge has taken the command, so the
    # read-back and broadcast that follow don't keep them locked. Freeing happens once, whichever comes first.
    def run(claim, kind)
      freed = false
      free = lambda do
        next if freed

        freed = true
        Hue::Locks.release(claim)
        HouseBroadcast.settle(claim.light_ids)
      end
      Rails.application.reloader.wrap { Hue::CallTimings.measure(kind) { yield free } }
    rescue StandardError => error
      Rails.logger.error("#{LOG_PREFIX} #{kind} #{error.class}: #{error.message}")
    ensure
      free&.call
    end

    def inline? = Rails.configuration.x.hue.dispatch_inline
  end
end
