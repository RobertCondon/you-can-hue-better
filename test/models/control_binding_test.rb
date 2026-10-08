require "test_helper"

class ControlBindingTest < ActiveSupport::TestCase
  setup do
    Hue::Sync.run(hue)
    @button = Hue::Control.find("b1")
    @zone = Hue::Group.find("z1")
  end

  test "a gesture does one thing per control" do
    ControlBinding.create!(control: @button, gesture: "short_release", action: "group_off", target: @zone)
    dup = ControlBinding.new(control: @button, gesture: "short_release", action: "group_on", target: @zone)
    refute dup.valid?
  end

  test "set_light needs a light and group actions need a group" do
    refute ControlBinding.new(control: @button, gesture: "short_release", action: "set_light", target: @zone).valid?
    refute ControlBinding.new(control: @button, gesture: "short_release", action: "group_on", target: Hue::Light.find("l1")).valid?
    assert ControlBinding.new(control: @button, gesture: "short_release", action: "webhook", settings: { url: "http://x" }).valid?
  end

  test "cycle state walks the steps and resets after the idle window" do
    b = ControlBinding.create!(control: @button, gesture: "short_release", action: "cycle_scenes", target: @zone, settings: { cycle_window_s: 10 })
    b.replace_steps!([ Hue::Scene.find("s1"), Hue::Scene.find("s2"), CustomScene.create!(name: "Mine") ])
    state = b.create_cycle_state!
    t = Time.current

    assert_equal "Relax", state.take!(now: t).scene.name
    assert_equal "Bright", state.take!(now: t + 2).scene.name
    assert_equal "Mine", state.peek.scene.name
    assert_equal "Mine", state.take!(now: t + 4).scene.name
    assert_equal "Relax", state.take!(now: t + 6).scene.name, "wraps around"
    assert_equal "Relax", state.take!(now: t + 30).scene.name, "idle for longer than the window restarts the cycle"
  end

  test "a custom scene captures the current mirror state" do
    scene = CustomScene.capture(name: "Now", lights: Hue::Light.all, group: Hue::Group.find("r1"))
    assert_equal 2, scene.states.count
    assert_equal 80.0, scene.states.find_by(light_id: "l1").brightness.to_f
    assert scene.fits_one_group?
  end
end
