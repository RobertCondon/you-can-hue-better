class FloorPolygon
  def initialize(points)
    @x_values = points.map { |point| point.first.to_f }
    @y_values = points.map { |point| point.last.to_f }
  end

  def centroid = [ average(@x_values), average(@y_values) ]

  def bounds
    { x: @x_values.min, y: @y_values.min, w: @x_values.max - @x_values.min, h: @y_values.max - @y_values.min }
  end

  private

  def average(values) = (values.sum / values.size).round(FloorCoordinates::DECIMAL_PLACES)
end
