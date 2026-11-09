# One line of a local button's list for a gesture: "if <room> is <on/off>, then <action> <room>".
# With no room to check it always matches, which makes it the "otherwise" at the bottom of a list.
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
  RECALL_SCENE = "recall_scene"
  ACTIONS = [ TURN_ON, TURN_OFF, TOGGLE, RECALL_SCENE ].freeze

  UP = "up"
  DOWN = "down"
  DIRECTIONS = [ UP, DOWN ].freeze

  belongs_to :local_button
  belongs_to :if_group, class_name: "Hue::Group", optional: true
  belongs_to :target_group, class_name: "Hue::Group", optional: true
  belongs_to :scene, class_name: "Hue::Scene", optional: true

  before_validation :tidy
  before_create :place_last

  validates :gesture, inclusion: { in: GESTURES }
  validates :action, inclusion: { in: ACTIONS }
  validates :target_group_id, presence: true
  validates :if_state, inclusion: { in: STATES }, unless: :always?
  validates :scene_id, presence: true, if: :recalls_scene?

  # What a new rule starts as: the first in a list turns a room on when it's off, and later ones turn
  # it off, so two clicks of "Add a rule" give a working on/off button.
  def self.starter(button, gesture)
    last = button.rules_for(gesture).last
    room_id = last&.target_group_id || Hue::Group.where(kind: Choices::KINDS).order(:kind, :name).pick(:id) # rooms before zones
    return { gesture:, action: TURN_OFF, target_group_id: room_id } if last

    { gesture:, if_group_id: room_id, if_state: OFF, action: TURN_ON, target_group_id: room_id }
  end

  def always? = if_group_id.blank?
  def recalls_scene? = action == RECALL_SCENE

  # A room counts as on when any of its lights is.
  def matches?
    return true if always?

    if_group.present? && room_on?(if_group) == (if_state == ON)
  end

  def runnable? = target_group.present? && (!recalls_scene? || scene.present?)

  # The room it checks, or the room or scene it changes, has gone from the bridge.
  def missing? = !runnable? || (!always? && if_group.nil?)

  def command
    case action
    when TURN_ON then HouseCommands::RoomSwitch.new(target_group, on: true)
    when TURN_OFF then HouseCommands::RoomSwitch.new(target_group, on: false)
    when TOGGLE then HouseCommands::RoomSwitch.new(target_group, on: !room_on?(target_group))
    when RECALL_SCENE then HouseCommands::SceneRecall.new(scene, Hue::Api::SceneRecall::STATIC_LOOK)
    end
  end

  def move!(direction)
    list = siblings.to_a
    from = list.index(self)
    to = direction == UP ? from - 1 : from + 1
    return if to.negative? || to >= list.size

    list[from], list[to] = list[to], list[from]
    transaction { list.each_with_index { |rule, position| rule.update_column(:position, position) } }
  end

  private

  def siblings = ButtonRule.where(local_button_id:, gesture:).order(:position, :id)

  def room_on?(group) = group.lights.any?(&:on?)

  def tidy
    self.if_group_id = if_group_id.presence
    self.if_state = always? ? nil : if_state.presence || ON
    self.scene_id = recalls_scene? ? scene_in_target_room : nil
  end

  # Keeps the scene when it belongs to the room being changed; otherwise picks that room's first one.
  def scene_in_target_room
    rooms_scenes = Hue::Scene.recallable.where(group_id: target_group_id)
    rooms_scenes.exists?(id: scene_id) ? scene_id : rooms_scenes.order(:name).pick(:id)
  end

  def place_last
    self.position = (siblings.maximum(:position) || -1) + 1
  end
end

# == Schema Information
#
# Table name: button_rules
#
#  id              :integer          not null, primary key
#  action          :string           not null
#  gesture         :string           not null
#  if_state        :string
#  position        :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  if_group_id     :string
#  local_button_id :integer          not null
#  scene_id        :string
#  target_group_id :string           not null
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
