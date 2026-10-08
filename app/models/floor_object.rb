# A wall or piece of furniture on a room's floor. Walls block light and bounce it back;
# furniture is just drawn. Positions are percent of the floor: x, y, w of its width; h of its height.
class FloorObject < ApplicationRecord
  KINDS = %w[wall box circle].freeze
  DEFAULTS = { "wall" => { w: 30, h: 3 }, "box" => { w: 18, h: 12 }, "circle" => { w: 12, h: 12 } }.freeze

  belongs_to :group, class_name: "Hue::Group"

  validates :kind, inclusion: { in: KINDS }
  validates :x, :y, numericality: { in: 0..100 }
  validates :w, :h, numericality: { in: 1..100 }
  validates :label, length: { maximum: 30 }, allow_nil: true
  validates :rotation, numericality: { only_integer: true, in: 0..359 }

  def self.add!(group_id:, kind:)
    d = DEFAULTS.fetch(kind) { raise ArgumentError, "unknown kind #{kind}" }
    create!(group_id:, kind:, x: 50 - d[:w] / 2.0, y: 50 - d[:h] / 2.0, w: d[:w], h: d[:h])
  end

  def wall?   = kind == "wall"
  def circle? = kind == "circle"

  def place!(attrs)
    update!(
      x: attrs[:x].to_f.clamp(0, 100).round(2), y: attrs[:y].to_f.clamp(0, 100).round(2),
      w: attrs[:w].to_f.clamp(1, 100).round(2), h: attrs[:h].to_f.clamp(1, 100).round(2),
      rotation: attrs.key?(:rotation) ? attrs[:rotation].to_i % 360 : rotation,
      label: attrs.key?(:label) ? attrs[:label].to_s.strip.presence : label
    )
  end
end
