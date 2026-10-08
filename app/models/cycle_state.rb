class CycleState < ApplicationRecord
  belongs_to :control_binding

  def idle_at?(moment) = last_pressed_at.nil? || last_pressed_at < moment - control_binding.cycle_window
end
