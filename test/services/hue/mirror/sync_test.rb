require "test_helper"

class Hue::Mirror::SyncTest < ActiveSupport::TestCase
  test "builds the mirror from the bridge" do
    counts = Hue::Mirror::Sync.call
    assert_equal({ devices: 3, lights: 2, groups: 3, scenes: 4, controls: 3 }, counts)

    dial = Hue::Device.find("d3")
    assert_equal "dial", dial.kind
    assert_equal 87, dial.battery_percent
    assert_equal [ 1, 2 ], dial.controls.buttons.order(:control_number).pluck(:control_number)
    assert dial.controls.rotaries.exists?

    assert_equal "light", Hue::Device.find("d1").kind
    refute Hue::Device.find("d2").reachable?, "connectivity_issue marks the device unreachable"
    refute Hue::Light.find("l2").reachable?

    study = Hue::Group.find("r1")
    assert_equal %w[l1 l2], study.lights.order(:id).pluck(:id)
    assert_equal "g1", study.grouped_light_id
    assert_equal 40.0, study.brightness.to_f
    assert_equal %w[Bright Natural\ light Relax], study.scenes.order(:name).pluck(:name)
    assert_equal "smart_scene", Hue::Scene.find("ss1").kind

    assert_equal %w[l1], Hue::Group.find("z1").lights.pluck(:id)
    home = Hue::Group.find_by(kind: "home")
    assert_equal 2, home.lights.count
    assert_equal "g0", home.grouped_light_id

    assert Hue::ListenerState.current.full_sync_at.present?
  end

  test "is idempotent and prunes what the bridge no longer reports" do
    Hue::Mirror::Sync.call
    Hue::Light.create!(id: "ghost", device_id: "d1", name: "Gone")
    Hue::Mirror::Sync.call
    assert_equal 2, Hue::Light.count
    refute Hue::Light.exists?("ghost")
  end

  test "light rows convert to the view snapshot" do
    Hue::Mirror::Sync.call
    snapshot = House::LightBuilder.from_mirror(Hue::Light.find("l1"))
    assert_equal House::Light, snapshot.class
    assert_equal "Desk lamp", snapshot.name
    assert_in_delta 0.4529, snapshot.xy[:x], 0.0001
  end
end
