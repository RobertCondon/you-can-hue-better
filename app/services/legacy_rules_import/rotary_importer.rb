class LegacyRulesImport
  class RotaryImporter
    BRIGHTNESS_KEY = "bri"
    BRIGHTNESS_STEP_KEY = "bri_inc"
    TRANSITION_KEY = "transitiontime"
    FROM_ANY_TURN = 0
    NEXT_STEP = 1

    def initialize(control:, rules:, outcome:)
      @control = control
      @rules = rules
      @outcome = outcome
      @bands = { ControlBinding::ROTATE_CLOCKWISE => [], ControlBinding::ROTATE_COUNTER_CLOCKWISE => [] }
      @turn_on_when_off = {}
    end

    def import
      group = @rules.flat_map(&:actions).filter_map { |action| Addresses.group_for(action.address) }.first
      return @outcome.skip(@rules, "unknown group") unless group

      @rules.each { |rule| read_rule(rule) }
      @bands.each do |gesture, bands|
        next if bands.empty?

        settings = { bands: bands.sort_by { |band| band[:min_steps] }, on_if_off: @turn_on_when_off }
        @outcome.save_binding(control: @control, gesture:, action: ControlBinding::BRIGHTNESS_DELTA, target: group, settings:)
      end
    end

    private

    def read_rule(rule)
      body = rule.action_matching(Addresses::GROUP_ACTION).body
      if rule.only_when_group_off?
        read_turn_on_band(rule, body)
      elsif body.key?(BRIGHTNESS_STEP_KEY)
        read_dimming_band(rule, body)
      end
    end

    def read_turn_on_band(rule, body)
      fast_turn = rule.rotation_above.to_i.positive?
      @turn_on_when_off[fast_turn ? :fast : :slow] = {
        brightness: V1Units.percent(body[BRIGHTNESS_KEY]),
        min_steps: fast_turn ? rule.rotation_above + NEXT_STEP : FROM_ANY_TURN,
        transition_ms: V1Units.milliseconds(body[TRANSITION_KEY])
      }.compact
    end

    def read_dimming_band(rule, body)
      clockwise = body[BRIGHTNESS_STEP_KEY].positive?
      threshold = clockwise ? rule.rotation_above : rule.rotation_below.abs
      gesture = clockwise ? ControlBinding::ROTATE_CLOCKWISE : ControlBinding::ROTATE_COUNTER_CLOCKWISE
      @bands[gesture] << {
        min_steps: threshold + NEXT_STEP,
        delta: V1Units.percent(body[BRIGHTNESS_STEP_KEY]).abs,
        transition_ms: V1Units.milliseconds(body[TRANSITION_KEY])
      }.compact
    end
  end
end
