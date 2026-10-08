class LegacyRulesImport
  module V1Units
    MAX_BRIGHTNESS = 254
    PERCENT = 100
    PERCENT_DECIMAL_PLACES = 1
    MILLISECONDS_PER_TRANSITION_STEP = 100

    module_function

    def percent(v1_brightness) = v1_brightness && (v1_brightness.to_f / MAX_BRIGHTNESS * PERCENT).round(PERCENT_DECIMAL_PLACES)

    def milliseconds(transition_steps) = transition_steps && transition_steps * MILLISECONDS_PER_TRANSITION_STEP
  end
end
