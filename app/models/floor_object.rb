class FloorObject < ApplicationRecord
  WALL = "wall"
  BOX = "box"
  CIRCLE = "circle"
  KINDS = [ WALL, BOX, CIRCLE ].freeze
  DEFAULT_SIZES = { WALL => { w: 30, h: 3 }, BOX => { w: 18, h: 12 }, CIRCLE => { w: 12, h: 12 } }.freeze
  FULL_TURN_DEGREES = 360
  MAX_LABEL_LENGTH = 30

  class UnknownKind < ArgumentError; end

  belongs_to :group, class_name: "Hue::Group"

  validates :kind, inclusion: { in: KINDS }
  validates :x, :y, numericality: { in: FloorCoordinates::POSITION_RANGE }
  validates :w, :h, numericality: { in: FloorCoordinates::SIZE_RANGE }
  validates :label, length: { maximum: MAX_LABEL_LENGTH }, allow_nil: true
  validates :rotation, numericality: { only_integer: true, in: 0...FULL_TURN_DEGREES }

  def wall? = kind == WALL
  def circle? = kind == CIRCLE
end
