class FloorNet < ApplicationRecord
  OUTLINE = "outline"
  ROOM = "room"
  MINIMUM_POINTS = 3
  MAX_LABEL_LENGTH = 30

  belongs_to :group, class_name: "Hue::Group", optional: true

  validates :label, length: { maximum: MAX_LABEL_LENGTH }, allow_nil: true
  validate :closes_a_loop

  scope :outlines, -> { where(group_id: nil) }
  scope :rooms, -> { where.not(group_id: nil) }

  def outline? = group_id.nil?
  def kind = outline? ? OUTLINE : ROOM
  def display_label = label.presence || group&.display_name || I18n.t("floor.net.house_label")
  def centroid = polygon.centroid
  def bbox = polygon.bounds

  def as_json(*)
    { id:, kind:, group_id:, label: display_label, points:, centroid:, bbox: }
  end

  private

  def polygon = FloorPolygon.new(points)

  def closes_a_loop
    errors.add(:points, :too_few, count: MINIMUM_POINTS) unless points.is_a?(Array) && points.size >= MINIMUM_POINTS
  end
end
