module Hue
  class Mirror
    class Listener
      class Backoff
        INITIAL_SECONDS = 1
        MAXIMUM_SECONDS = 30
        GROWTH_FACTOR = 2

        attr_reader :seconds

        def initialize = reset

        def reset = @seconds = INITIAL_SECONDS

        def increase = @seconds = [ seconds * GROWTH_FACTOR, MAXIMUM_SECONDS ].min
      end
    end
  end
end
