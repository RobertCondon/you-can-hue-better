class Floor
  class Net < ApplicationRecord
    self.table_name = "floor_nets"

    OUTLINE = "outline"
    ROOM = "room"
    MINIMUM_POINTS = 3
    MAX_LABEL_LENGTH = 30
    COORDINATES_PER_POINT = 2

    belongs_to :group, class_name: "Hue::Group", optional: true

    validates :label, length: { maximum: MAX_LABEL_LENGTH }, allow_nil: true
    validate :closes_a_loop

    scope :outlines, -> { where(group_id: nil) }
    scope :rooms, -> { where.not(group_id: nil) }

    def self.draw!(attributes)
      net = new(attributes)
      transaction do
        outlines.delete_all if net.outline?
        net.save!
      end
      net
    end

    def self.parse_points(raw_points)
      points = Array(raw_points.is_a?(String) ? JSON.parse(raw_points) : raw_points)
      points = points.flatten.each_slice(COORDINATES_PER_POINT).to_a unless points.first.is_a?(Array)
      points.map { |point_x, point_y| [ Coordinates.position(point_x), Coordinates.position(point_y) ] }
    end

    def outline? = group_id.nil?
    def kind = outline? ? OUTLINE : ROOM
    def display_label = label.presence || group&.display_name || I18n.t("floor.net.house_label")
    def centroid = polygon.centroid
    def bbox = polygon.bounds
    def svg_points = polygon.svg_points
    def void_path = polygon.void_path

    def as_json(*)
      { id:, kind:, group_id:, label: display_label, points:, centroid:, bbox: }
    end

    private

    def polygon = Polygon.new(points)

    def closes_a_loop
      errors.add(:points, :too_few, count: MINIMUM_POINTS) unless points.is_a?(Array) && points.size >= MINIMUM_POINTS
    end
  end
end

# == Schema Information
#
# Table name: floor_nets
#
#  id         :integer          not null, primary key
#  label      :string
#  points     :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :string
#
# Indexes
#
#  index_floor_nets_on_group_id  (group_id)
#
# Foreign Keys
#
#  group_id  (group_id => hue_groups.id) ON DELETE => cascade
#
