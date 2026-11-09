# One line of a local button's list for a gesture: "if <room or light> is <on/off>, then <action>
# <room or light>". With nothing to check it always matches, which makes it the "otherwise" at the
# bottom of a list. ButtonRules:: holds what a rule does: checking, running, moving, starting.
class ButtonRule < ApplicationRecord
  SINGLE = "single"
  DOUBLE = "double"
  GESTURES = [ SINGLE, DOUBLE ].freeze

  ON = "on"
  OFF = "off"
  STATES = [ ON, OFF ].freeze

  TURN_ON = "turn_on"
  TURN_OFF = "turn_off"
  TOGGLE = "toggle"
  SET_BRIGHTNESS = "set_brightness"
  RECALL_SCENE = "recall_scene"
  ACTIONS = [ TURN_ON, TURN_OFF, TOGGLE, SET_BRIGHTNESS, RECALL_SCENE ].freeze

  ROOM = "Hue::Group"
  LIGHT = "Hue::Light"
  SUBJECT_TYPES = [ ROOM, LIGHT ].freeze

  DEFAULT_BRIGHTNESS = 50

  UP = "up"
  DOWN = "down"
  DIRECTIONS = [ UP, DOWN ].freeze

  belongs_to :local_button
  belongs_to :if_subject, polymorphic: true, optional: true
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :scene, class_name: "Hue::Scene", optional: true

  before_validation :tidy
  before_create :place_last

  validates :gesture, inclusion: { in: GESTURES }
  validates :action, inclusion: { in: ACTIONS }
  validates :target_type, inclusion: { in: SUBJECT_TYPES }
  validates :target_id, presence: true
  validates :if_subject_type, inclusion: { in: SUBJECT_TYPES }, unless: :always?
  validates :if_state, inclusion: { in: STATES }, unless: :always?
  validates :brightness, numericality: { only_integer: true, in: Hue::Api::Limits::LIT_BRIGHTNESS }, if: :sets_brightness?
  validates :scene_id, presence: true, if: -> { recalls_scene? && targets_room? }
  validate :scene_needs_a_room, if: :recalls_scene?

  def always? = if_subject_id.blank?
  def recalls_scene? = action == RECALL_SCENE
  def sets_brightness? = action == SET_BRIGHTNESS
  def targets_room? = target_type == ROOM

  def runnable? = target.present? && (!recalls_scene? || scene.present?)

  # What it checks, or the room, light or scene it changes, has gone from the bridge.
  def missing? = !runnable? || (!always? && if_subject.nil?)

  private

  def tidy
    self.if_subject_id = if_subject_id.presence
    self.if_subject_type = nil if always?
    self.if_state = always? ? nil : if_state.presence || ON
    self.brightness = sets_brightness? ? brightness.presence || DEFAULT_BRIGHTNESS : nil
    self.scene_id = recalls_scene? && targets_room? ? scene_in_target_room : nil
  end

  # Keeps the scene when it belongs to the room being changed; otherwise picks that room's first one.
  def scene_in_target_room
    rooms_scenes = Hue::Scene.recallable.where(group_id: target_id)
    rooms_scenes.exists?(id: scene_id) ? scene_id : rooms_scenes.order(:name).pick(:id)
  end

  def scene_needs_a_room
    errors.add(:base, :scene_needs_a_room) unless targets_room?
  end

  def place_last
    self.position = (ButtonRule.where(local_button_id:, gesture:).maximum(:position) || -1) + 1
  end
end

# == Schema Information
#
# Table name: button_rules
#
#  id              :integer          not null, primary key
#  action          :string           not null
#  brightness      :integer
#  gesture         :string           not null
#  if_state        :string
#  if_subject_type :string
#  position        :integer          not null
#  target_type     :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  if_subject_id   :string
#  local_button_id :integer          not null
#  scene_id        :string
#  target_id       :string           not null
#
# Indexes
#
#  index_button_rules_on_local_button_id                           (local_button_id)
#  index_button_rules_on_local_button_id_and_gesture_and_position  (local_button_id,gesture,position)
#
# Foreign Keys
#
#  local_button_id  (local_button_id => local_buttons.id)
#
