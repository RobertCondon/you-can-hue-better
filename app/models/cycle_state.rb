class CycleState < ApplicationRecord
  FIRST_POSITION = 0

  belongs_to :control_binding

  def idle_at?(moment) = last_pressed_at.nil? || last_pressed_at < moment - control_binding.cycle_window

  def advance!(at: Time.current)
    return if steps.empty?

    current_position = position_at(at)
    update!(position: (current_position + 1) % steps.size, last_pressed_at: at)
    steps[current_position]
  end

  def upcoming_step(at: Time.current) = steps.empty? ? nil : steps[position_at(at)]

  private

  def position_at(moment) = idle_at?(moment) ? FIRST_POSITION : position % steps.size

  def steps = @steps ||= control_binding.steps.to_a
end

# == Schema Information
#
# Table name: cycle_states
#
#  id                 :integer          not null, primary key
#  last_pressed_at    :datetime
#  position           :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  control_binding_id :integer          not null
#
# Indexes
#
#  index_cycle_states_on_control_binding_id  (control_binding_id) UNIQUE
#
# Foreign Keys
#
#  control_binding_id  (control_binding_id => control_bindings.id)
#
