class Floor
  class Item < ApplicationRecord
    self.table_name = "floor_objects"

    WALL = "wall"
    BOX = "box"
    CIRCLE = "circle"
    KINDS = [ WALL, BOX, CIRCLE ].freeze
    DEFAULT_SIZES = { WALL => { w: 30, h: 3 }, BOX => { w: 18, h: 12 }, CIRCLE => { w: 12, h: 12 } }.freeze
    FULL_TURN_DEGREES = 360
    MAX_LABEL_LENGTH = 30
    FLOOR_CENTRE = 50
    HALF = 2.0

    class UnknownKind < ArgumentError; end

    belongs_to :group, class_name: "Hue::Group"

    validates :kind, inclusion: { in: KINDS }
    validates :x, :y, numericality: { in: Coordinates::POSITION_RANGE }
    validates :w, :h, numericality: { in: Coordinates::SIZE_RANGE }
    validates :label, length: { maximum: MAX_LABEL_LENGTH }, allow_nil: true
    validates :rotation, numericality: { only_integer: true, in: 0...FULL_TURN_DEGREES }

    def self.create_centred!(group_id:, kind:)
      size = DEFAULT_SIZES.fetch(kind) { raise UnknownKind, kind }
      create!(group_id:, kind:, x: FLOOR_CENTRE - size[:w] / HALF, y: FLOOR_CENTRE - size[:h] / HALF, **size)
    end

    def place!(changes)
      update!(
        x: Coordinates.position(changes[:x]), y: Coordinates.position(changes[:y]),
        w: Coordinates.size(changes[:w]), h: Coordinates.size(changes[:h]),
        rotation: changes.key?(:rotation) ? changes[:rotation].to_i % FULL_TURN_DEGREES : rotation,
        label: changes.key?(:label) ? changes[:label].to_s.strip.presence : label
      )
    end

    def wall? = kind == WALL
    def circle? = kind == CIRCLE
  end
end
