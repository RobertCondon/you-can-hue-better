# A light's spot on a room's floor: x and y as 0..100 percent. Set by dragging in Edit floor.
class LightPlacement < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group"
  belongs_to :light, class_name: "Hue::Light"

  validates :x, :y, numericality: { in: 0..100 }
  validates :light_id, uniqueness: { scope: :group_id }

  def self.place!(group_id:, light_id:, x:, y:)
    find_or_initialize_by(group_id:, light_id:).tap { _1.update!(x: x.to_f.clamp(0, 100).round(2), y: y.to_f.clamp(0, 100).round(2)) }
  end

  # { light_id => [x, y] } for one room.
  def self.map_for(group_id) = where(group_id:).pluck(:light_id, :x, :y).to_h { |id, x, y| [ id, [ x.to_f, y.to_f ] ] }
end
