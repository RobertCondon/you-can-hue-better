module ControlBindings
  class SceneCycle
    FIRST_POSITION = 0

    def initialize(cycle_state)
      @cycle_state = cycle_state
    end

    def advance!(at: Time.current)
      return if steps.empty?

      position = @cycle_state.idle_at?(at) ? FIRST_POSITION : @cycle_state.position
      @cycle_state.update!(position: (position + 1) % steps.size, last_pressed_at: at)
      steps[position % steps.size]
    end

    def upcoming_step(at: Time.current)
      return if steps.empty?

      steps[@cycle_state.idle_at?(at) ? FIRST_POSITION : @cycle_state.position % steps.size]
    end

    private

    def steps = @steps ||= @cycle_state.control_binding.steps.to_a
  end
end
