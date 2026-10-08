module FloorNets
  module PointsParam
    COORDINATES_PER_POINT = 2

    module_function

    def parse(raw_points)
      points = Array(raw_points.is_a?(String) ? JSON.parse(raw_points) : raw_points)
      points = points.flatten.each_slice(COORDINATES_PER_POINT).to_a unless points.first.is_a?(Array)
      points.map { |point_x, point_y| [ FloorCoordinates.position(point_x), FloorCoordinates.position(point_y) ] }
    end
  end
end
