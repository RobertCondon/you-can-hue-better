class ControlBinding < ApplicationRecord
  INITIAL_PRESS = "initial_press"
  REPEAT = "repeat"
  SHORT_RELEASE = "short_release"
  LONG_PRESS = "long_press"
  LONG_RELEASE = "long_release"
  ROTATE_CLOCKWISE = "rotate_cw"
  ROTATE_COUNTER_CLOCKWISE = "rotate_ccw"
  GESTURES = [ INITIAL_PRESS, REPEAT, SHORT_RELEASE, LONG_PRESS, LONG_RELEASE, ROTATE_CLOCKWISE, ROTATE_COUNTER_CLOCKWISE ].freeze

  RECALL_SCENE = "recall_scene"
  CYCLE_SCENES = "cycle_scenes"
  TOGGLE_GROUP = "toggle_group"
  GROUP_ON = "group_on"
  GROUP_OFF = "group_off"
  BRIGHTNESS_DELTA = "brightness_delta"
  SET_LIGHT = "set_light"
  WEBHOOK = "webhook"
  JOB = "job"
  SCENE_ACTIONS = [ RECALL_SCENE, CYCLE_SCENES ].freeze
  GROUP_ACTIONS = [ *SCENE_ACTIONS, TOGGLE_GROUP, GROUP_ON, GROUP_OFF, BRIGHTNESS_DELTA ].freeze
  TARGETED_ACTIONS = [ *GROUP_ACTIONS, SET_LIGHT ].freeze
  ACTIONS = [ *TARGETED_ACTIONS, WEBHOOK, JOB ].freeze

  CYCLE_WINDOW_SETTING = "cycle_window_s"
  DEFAULT_CYCLE_WINDOW_SECONDS = 10

  belongs_to :control, class_name: "Hue::Control"
  belongs_to :target, polymorphic: true, optional: true
  has_many :steps, -> { order(:position) }, class_name: "ControlBindingStep", dependent: :destroy
  has_one :cycle_state, dependent: :destroy

  validates :gesture, inclusion: { in: GESTURES }, uniqueness: { scope: :control_id }
  validates :action, inclusion: { in: ACTIONS }
  validates :target, presence: true, if: :targeted?
  validate :target_suits_action

  scope :enabled, -> { where(enabled: true) }

  def targeted? = action.in?(TARGETED_ACTIONS)
  def cycle? = action == CYCLE_SCENES
  def cycle_window = settings.fetch(CYCLE_WINDOW_SETTING, DEFAULT_CYCLE_WINDOW_SECONDS).to_i.seconds
  def scenes = steps.map(&:scene)

  def replace_steps!(scenes)
    transaction do
      steps.destroy_all
      scenes.each_with_index { |scene, position| steps.create!(position:, scene:) }
      cycle_state&.update!(position: 0)
    end
  end

  private

  def target_suits_action
    return if target.nil?

    if action == SET_LIGHT
      errors.add(:target, :must_be_light) unless target.is_a?(Hue::Light)
    elsif !target.is_a?(Hue::Group)
      errors.add(:target, :must_be_group)
    end
  end
end
