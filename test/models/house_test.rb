require "test_helper"

class HouseTest < ActiveSupport::TestCase
  test "assembles rooms with their lights and scenes from the mirror" do
    sync_mirror!
    house = House.load
    study = house.room("r1")
    assert_equal %w[Corner\ lamp Desk\ lamp], study.lights.map(&:name)
    assert_equal [ "Bright", "Relax" ], study.scenes.map(&:name), "smart scenes are not recallable, so they are left out"
    assert_equal "g1", study.grouped_light_id
    assert_equal "1 of 2 on", study.summary
    assert_equal "zone", house.room("z1").kind
    assert_equal 1, house.on_count
  end

  test "default order is most lights, then most on, then name" do
    sync_mirror!
    assert_equal %w[Study Evening], House.load.rooms.map(&:name), "Study has two lights, Evening one"

    attic = Hue::Group.create!(id: "r2", kind: Hue::Group::ROOM, name: "Attic", grouped_light_id: "g9")
    Hue::GroupLight.create!(group: attic, light_id: "l1")
    Hue::GroupLight.create!(group: attic, light_id: "l2")
    assert_equal %w[Attic Study Evening], House.load.rooms.map(&:name), "same size and same on count: alphabetical"

    Hue::Light.find("l2").update!(on: true)
    assert_equal %w[Attic Study Evening], House.load.rooms.map(&:name)
    Hue::GroupLight.where(group: attic, light_id: "l2").delete_all
    assert_equal %w[Study Attic Evening], House.load.rooms.map(&:name), "Study now has more lights than Attic"
  end

  test "saved positions win, and unplaced rooms follow in default order" do
    sync_mirror!
    HueExtensions::Group.set_order!(%w[z1])
    assert_equal %w[Evening Study], House.load.rooms.map(&:name)
    assert_equal 0, House.load.room("z1").position
    assert_nil House.load.room("r1").position
  end

  test "refreshes from the bridge first when the listener is not live" do
    assert Hue::Light.none?
    House.load
    assert_equal 2, Hue::Light.count
  end

  test "does not touch the bridge when the listener is live" do
    sync_mirror!
    Hue.client = Object.new.tap { |untouchable| untouchable.define_singleton_method(:lights) { raise "should not be called" } }
    assert_equal 2, House.load.lights.size
  end

  test "renders stale data if the bridge is down but the mirror has it, and raises if it is empty" do
    sync_mirror!
    Hue::ListenerState.current.disconnected!
    Hue.client = Object.new.tap { |unreachable| unreachable.define_singleton_method(:devices) { raise Hue::Error, "down" } }
    assert_equal 2, House.load.lights.size

    Hue::Light.destroy_all
    assert_raises(Hue::Error) { House.load }
  end
end
