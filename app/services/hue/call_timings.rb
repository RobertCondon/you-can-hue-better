module Hue
  module CallTimings
    WINDOW = 100
    MINIMUM_SAMPLES = 20
    PERCENTILE = 0.95
    MILLISECONDS_PER_SECOND = 1000
    DEFAULT_MILLISECONDS = 1000
    FLOOR_MILLISECONDS = 250
    CEILING_MILLISECONDS = (Api::PersistentConnection::OPEN_TIMEOUT_SECONDS + Api::PersistentConnection::READ_TIMEOUT_SECONDS) * MILLISECONDS_PER_SECOND
    GUARD = Mutex.new
    SAMPLES = Hash.new { |samples, kind| samples[kind] = [] }

    module_function

    def measure(kind)
      started_at = now
      yield
    ensure
      record(kind, now - started_at)
    end

    def record(kind, seconds)
      GUARD.synchronize do
        durations = SAMPLES[kind]
        durations << seconds
        durations.shift while durations.size > WINDOW
      end
    end

    def p95_milliseconds(kind)
      durations = GUARD.synchronize { SAMPLES[kind].sort }
      return DEFAULT_MILLISECONDS if durations.size < MINIMUM_SAMPLES

      slowest_typical = durations[(durations.size * PERCENTILE).ceil - 1]
      (slowest_typical * MILLISECONDS_PER_SECOND).round.clamp(FLOOR_MILLISECONDS, CEILING_MILLISECONDS)
    end

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
