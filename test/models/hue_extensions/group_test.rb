require "test_helper"

class HueExtensions::GroupTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "shares its id with the mirror row and is reachable from it" do
    HueExtensions::Group.create!(id: "r1", position: 3)
    assert_equal 3, Hue::Group.find("r1").extension.position
    assert_equal "Study", HueExtensions::Group.find("r1").hue_group.name
  end

  test "setting the order places listed rooms and unplaces the rest without deleting their rows" do
    HueExtensions::Group.set_order!(%w[z1 r1])
    assert_equal [ [ "z1", 0 ], [ "r1", 1 ] ], HueExtensions::Group.order(:position).pluck(:id, :position)
    HueExtensions::Group.set_order!(%w[r1])
    assert_equal [ [ "r1", 0 ] ], HueExtensions::Group.where.not(position: nil).pluck(:id, :position)
    assert_nil HueExtensions::Group.find("z1").position, "row kept for future settings"
  end

  test "goes away with its room" do
    HueExtensions::Group.create!(id: "r1", position: 0)
    Hue::Group.find("r1").destroy!
    refute HueExtensions::Group.exists?("r1")
  end
end
