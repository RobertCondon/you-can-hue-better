# A closed loop on the floor. With a group it names a room's region ("net"); without one it is the
# house outline. Points are [[x, y], ...] in percent of the floor; at least three.
class FloorNet < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group", optional: true

  validates :label, length: { maximum: 30 }, allow_nil: true
  validate :enough_points

  scope :outlines, -> { where(group_id: nil) }
  scope :rooms,    -> { where.not(group_id: nil) }

  def outline? = group_id.nil?
  def kind     = outline? ? "outline" : "room"

  def display_label = label.presence || group&.display_name || "House"

  def centroid
    xs = points.map { _1[0].to_f }; ys = points.map { _1[1].to_f }
    [ (xs.sum / xs.size).round(2), (ys.sum / ys.size).round(2) ]
  end

  def bbox
    xs = points.map { _1[0].to_f }; ys = points.map { _1[1].to_f }
    { x: xs.min, y: ys.min, w: xs.max - xs.min, h: ys.max - ys.min }
  end

  # Accepts [[x, y], ...], a flat [x, y, x, y, ...] (how form encoding arrives), or a JSON string of either.
  def self.clean_points(raw)
    raw = JSON.parse(raw) if raw.is_a?(String)
    list = Array(raw)
    list = list.flatten.each_slice(2).to_a unless list.first.is_a?(Array)
    list.map { |p| [ p[0].to_f.clamp(0, 100).round(2), p[1].to_f.clamp(0, 100).round(2) ] }
  end

  def as_json(*)
    { id:, kind:, group_id:, label: display_label, points: points, centroid: centroid, bbox: bbox }
  end

  private

  def enough_points
    errors.add(:points, "needs at least three points") unless points.is_a?(Array) && points.size >= 3
  end
end
