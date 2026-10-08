require "test_helper"

class FloorNetsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "closing a loop makes a room net; its points are cleaned and it is returned as json" do
    post floor_nets_path, params: { group_id: "r1", points: [ [ 10, 10 ], [ 60.123, 10 ], [ 60, 50 ], [ 10, 120 ] ] }
    assert_response :created
    net = FloorNet.last
    assert_equal [ "r1", [ [ 10.0, 10.0 ], [ 60.12, 10.0 ], [ 60.0, 50.0 ], [ 10.0, 100.0 ] ] ], [ net.group_id, net.points ]
    assert_equal "room", response.parsed_body["kind"]
    assert_equal "Study", response.parsed_body["label"]
    assert_equal [ 35.03, 42.5 ], response.parsed_body["centroid"]
  end

  test "an outline has no room, and there is only ever one" do
    post floor_nets_path, params: { points: [ [ 0, 0 ], [ 100, 0 ], [ 100, 100 ] ] }
    post floor_nets_path, params: { points: [ [ 1, 1 ], [ 99, 1 ], [ 99, 99 ], [ 1, 99 ] ] }
    assert_equal 1, FloorNet.outlines.count
    assert_equal 4, FloorNet.outlines.first.points.size
    assert_equal "House", FloorNet.outlines.first.display_label
  end

  test "fewer than three points is refused" do
    post floor_nets_path, params: { group_id: "r1", points: [ [ 10, 10 ], [ 20, 20 ] ] }
    assert_response :unprocessable_entity
  end

  test "points, room and label can change; removing works" do
    net = FloorNet.create!(group_id: "r1", points: [ [ 0, 0 ], [ 10, 0 ], [ 10, 10 ] ])
    patch floor_net_path(net), params: { group_id: "z1", label: " Reading corner ", points: [ [ 0, 0 ], [ 20, 0 ], [ 20, 20 ], [ 0, 20 ] ] }
    assert_response :success
    net.reload
    assert_equal [ "z1", "Reading corner", 4 ], [ net.group_id, net.label, net.points.size ]
    delete floor_net_path(net)
    assert_response :no_content
    refute FloorNet.exists?(net.id)
  end

  test "the floor draws nets, the outline's void, labels for rooms, and the drawing tools" do
    FloorNet.create!(points: [ [ 2, 2 ], [ 98, 2 ], [ 98, 98 ], [ 2, 98 ] ])
    FloorNet.create!(group_id: "r1", points: [ [ 5, 5 ], [ 50, 5 ], [ 50, 50 ], [ 5, 50 ] ])
    get floor_path
    assert_select ".floor__nets polygon.floor__net--outline[data-kind=outline]", 1
    assert_select ".floor__nets polygon.floor__net--room[data-group-id=r1][data-points]", 1
    assert_select ".floor__nets .floor__void[d^='M0 0H100V100H0Z M2 2']", 1
    assert_select ".floor__world .floor__netlabel[data-net-id][style*='--x: 27.5']", "Study"
    assert_select ".floor-head .tool--draw[data-floor-tool-param=room]"
    assert_select ".floor-head .tool--draw[data-floor-tool-param=outline]"
    assert_select "[data-floor-target=netRoom] option[value=r1]", "Study"
  end

  test "a scene's floor shows nets but cannot select them" do
    FloorNet.create!(group_id: "r1", points: [ [ 5, 5 ], [ 50, 5 ], [ 50, 50 ] ])
    get scene_path("s1")
    assert_select ".floor__nets polygon.floor__net--room", 1
    assert_select ".floor__nets polygon[data-action]", 0
  end
end
