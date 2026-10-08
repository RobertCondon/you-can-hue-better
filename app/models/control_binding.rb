# What one control does for one gesture. The unique index on (control, gesture) means a gesture
# does exactly one thing, which is what the Hue app enforces too.
class ControlBinding < ApplicationRecord
  GESTURES = %w[initial_press repeat short_release long_press long_release rotate_cw rotate_ccw].freeze
  ACTIONS  = %w[recall_scene cycle_scenes toggle_group group_on group_off brightness_delta set_light webhook job].freeze
  TARGETED = %w[recall_scene cycle_scenes toggle_group group_on group_off brightness_delta set_light].freeze
  SCENED   = %w[recall_scene cycle_scenes].freeze

  belongs_to :control, class_name: "Hue::Control"
  belongs_to :target, polymorphic: true, optional: true
  has_many :steps, -> { order(:position) }, class_name: "ControlBindingStep", dependent: :destroy
  has_one :cycle_state, dependent: :destroy

  validates :gesture, inclusion: { in: GESTURES }
  validates :action, inclusion: { in: ACTIONS }
  validates :gesture, uniqueness: { scope: :control_id }
  validates :target, presence: true, if: -> { action.in?(TARGETED) }
  validate :target_matches_action

  scope :enabled, -> { where(enabled: true) }

  def cycle?          = action == "cycle_scenes"
  def cycle_window    = (settings["cycle_window_s"] || 10).to_i.seconds
  def scenes          = steps.map(&:scene)

  def replace_steps!(scenes)
    transaction do
      steps.destroy_all
      scenes.each_with_index { |s, i| steps.create!(position: i, scene: s) }
      cycle_state&.update!(position: 0)
    end
  end

  private

  def target_matches_action
    return if target.nil?
    wants = action == "set_light" ? Hue::Light : Hue::Group
    errors.add(:target, "must be a #{wants.name.demodulize.downcase} for #{action}") unless target.is_a?(wants)
  end
end
