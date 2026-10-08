class FloorPolygon
  FLOOR_SQUARE_PATH = "M0 0H100V100H0Z"

  def initialize(points)
    @points = points
    @x_values = points.map { |point| point.first.to_f }
    @y_values = points.map { |point| point.last.to_f }
  end

  def centroid = [ average(@x_values), average(@y_values) ]

  def bounds
    { x: @x_values.min, y: @y_values.min, w: @x_values.max - @x_values.min, h: @y_values.max - @y_values.min }
  end

  def svg_points = @points.map { |point| point.join(",") }.join(" ")

  def void_path = "#{FLOOR_SQUARE_PATH} M#{@points.map { |point| point.join(" ") }.join(" L ")} Z"

  private

  def average(values) = (values.sum / values.size).round(FloorCoordinates::DECIMAL_PLACES)
end
