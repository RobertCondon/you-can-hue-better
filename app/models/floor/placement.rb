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

# == Schema Information
#
# Table name: light_placements
#
#  id         :integer          not null, primary key
#  x          :decimal(5, 2)    not null
#  y          :decimal(5, 2)    not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :string           not null
#  light_id   :string           not null
#
# Indexes
#
#  index_light_placements_on_group_id               (group_id)
#  index_light_placements_on_group_id_and_light_id  (group_id,light_id) UNIQUE
#  index_light_placements_on_light_id               (light_id)
#
# Foreign Keys
#
#  group_id  (group_id => hue_groups.id) ON DELETE => cascade
#  light_id  (light_id => hue_lights.id) ON DELETE => cascade
#
