# Where a cycle_scenes binding is in its list. Mirrors the v1 rules' hidden status sensors:
# the position resets to the start after the binding's idle window.
class CycleState < ApplicationRecord
  belongs_to :control_binding

  # Returns the step for a press happening now and advances. nil when the binding has no steps.
  def take!(now: Time.current)
    steps = control_binding.steps.to_a
    return nil if steps.empty?

    self.position = 0 if last_pressed_at.nil? || last_pressed_at < now - control_binding.cycle_window
    step = steps[position % steps.size]
    update!(position: (position + 1) % steps.size, last_pressed_at: now)
    step
  end

  def peek
    steps = control_binding.steps.to_a
    return nil if steps.empty?
    idle = last_pressed_at.nil? || last_pressed_at < Time.current - control_binding.cycle_window
    steps[idle ? 0 : position % steps.size]
  end
end
