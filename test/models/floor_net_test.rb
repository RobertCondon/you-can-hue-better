require "test_helper"

class FloorNetTest < ActiveSupport::TestCase
  test "points arrive as pairs, a flat list from a form, or JSON, and are kept on the floor" do
    expected = [ [ 10.0, 20.0 ], [ 100.0, 0.0 ], [ 33.33, 40.0 ] ]
    assert_equal expected, FloorNets::PointsParam.parse([ [ 10, 20 ], [ 140, -5 ], [ 33.333, 40 ] ])
    assert_equal expected, FloorNets::PointsParam.parse(%w[10 20 140 -5 33.333 40])
    assert_equal expected, FloorNets::PointsParam.parse("[[10,20],[140,-5],[33.333,40]]")
  end

  test "a net knows its centre and its bounds" do
    net = FloorNet.new(points: [ [ 0, 0 ], [ 40, 0 ], [ 40, 20 ], [ 0, 20 ] ])
    assert_equal [ 20.0, 10.0 ], net.centroid
    assert_equal({ x: 0.0, y: 0.0, w: 40.0, h: 20.0 }, net.bbox)
  end

  test "fewer than three points is not a loop" do
    net = FloorNet.new(points: [ [ 0, 0 ], [ 1, 1 ] ])
    refute net.valid?
    assert_includes net.errors[:points], "needs at least 3 points"
  end
end
