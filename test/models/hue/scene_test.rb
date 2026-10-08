require "test_helper"

class Hue::SceneTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  def relax = Hue::Scene.find("s1")

  test "sync fills the scene's detail and one action per light" do
    assert_equal "inactive", relax.active
    assert_equal 0.5, relax.speed.to_f
    assert_equal "img-relax", relax.image_id
    assert_equal 2, relax.actions.count
    desk_lamp_action = relax.actions.find_by(light_id: "l1")
    assert_equal [ true, 38.0, 0.5, nil ], [ desk_lamp_action.on, desk_lamp_action.brightness.to_f, desk_lamp_action.color_x.to_f, desk_lamp_action.mirek ]
    assert_equal 400, relax.actions.find_by(light_id: "l2").mirek
  end

  test "a recall timestamp sent as an object on older firmware is ignored" do
    scene = relax
    scene.assign_from_raw(scene.raw.merge("status" => { "active" => "static", "last_recall" => { "source" => "app" } }))
    assert_equal "static", scene.active
    assert_nil scene.last_recalled_at
  end

  test "palette hexes and dynamic?" do
    assert relax.dynamic?
    assert_equal 2, relax.palette_hexes.size
    refute Hue::Scene.find("s2").dynamic?
  end

  test "an action renders like a light" do
    snapshot = relax.actions.find_by(light_id: "l1").to_snapshot
    assert_equal House::Light, snapshot.class
    assert_equal "xy", snapshot.color_mode
    assert_equal "38%", snapshot.brightness_label
    assert_equal "Not responding", relax.actions.find_by(light_id: "l2").to_snapshot.brightness_label, "Corner lamp's device has a connectivity issue"
    assert_match(/\A#[0-9a-f]{6}\z/, snapshot.tile_hex)
  end

  test "stock siblings share an image id" do
    assert_equal [ "s3" ], relax.siblings.pluck(:id)
    assert_empty Hue::Scene.find("s2").siblings
  end

  test "dots sort into a spectrum" do
    angles = relax.actions.sort_by(&:hue_angle).map(&:hue_angle)
    assert_equal angles.sort, angles
  end
end
