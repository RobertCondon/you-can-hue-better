class Floor
  class Placement < ApplicationRecord
    self.table_name = "light_placements"

    belongs_to :group, class_name: "Hue::Group"
    belongs_to :light, class_name: "Hue::Light"

    validates :x, :y, numericality: { in: Coordinates::POSITION_RANGE }
    validates :light_id, uniqueness: { scope: :group_id }

    def self.place!(group_id:, light_id:, x:, y:)
      find_or_initialize_by(group_id:, light_id:).tap do |placement|
        placement.update!(x: Coordinates.position(x), y: Coordinates.position(y))
      end
    end

    def self.positions_on(group_id)
      where(group_id:).pluck(:light_id, :x, :y).to_h { |light_id, placed_x, placed_y| [ light_id, [ placed_x.to_f, placed_y.to_f ] ] }
    end
  end
end
