require "test_helper"

class Hue::SceneTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "sync fills the scene's detail and one action per light" do
    s = Hue::Scene.find("s1")
    assert_equal "inactive", s.active
    assert_equal 0.5, s.speed.to_f
    assert_equal "img-relax", s.image_id
    assert_equal 2, s.actions.count
    a = s.actions.find_by(light_id: "l1")
    assert_equal [ true, 38.0, 0.5, nil ], [ a.on, a.brightness.to_f, a.color_x.to_f, a.mirek ]
    assert_equal 400, s.actions.find_by(light_id: "l2").mirek
  end

  test "palette hexes and dynamic?" do
    assert Hue::Scene.find("s1").dynamic?
    assert_equal 2, Hue::Scene.find("s1").palette_hexes.size
    refute Hue::Scene.find("s2").dynamic?
  end

  test "an action renders like a light" do
    snap = Hue::Scene.find("s1").actions.find_by(light_id: "l1").to_snapshot
    assert_equal House::Light, snap.class
    assert_equal "xy", snap.color_mode
    assert_equal "38%", snap.brightness_label
    assert_equal "Not responding", Hue::Scene.find("s1").actions.find_by(light_id: "l2").to_snapshot.brightness_label, "Corner lamp's device has a connectivity issue"
    assert_match(/\A#[0-9a-f]{6}\z/, snap.tile_hex)
  end

  test "stock siblings share an image id" do
    assert_equal [ "s3" ], Hue::Scene.find("s1").siblings.pluck(:id)
    assert_empty Hue::Scene.find("s2").siblings
  end

  test "dots sort into a spectrum" do
    angles = Hue::Scene.find("s1").actions.sort_by(&:hue_angle).map(&:hue_angle)
    assert_equal angles.sort, angles
  end
end
