require "test_helper"

class ControlBindingTest < ActiveSupport::TestCase
  setup do
    Hue::Mirror::Sync.call
    @button = Hue::Control.find("b1")
    @zone = Hue::Group.find("z1")
  end

  def binding(action, target: @zone, **attributes)
    ControlBinding.new(control: @button, gesture: ControlBinding::SHORT_RELEASE, action:, target:, **attributes)
  end

  test "a gesture does one thing per control" do
    binding(ControlBinding::GROUP_OFF).save!
    refute binding(ControlBinding::GROUP_ON).valid?
  end

  test "set_light needs a light and group actions need a group" do
    refute binding(ControlBinding::SET_LIGHT).valid?
    refute binding(ControlBinding::GROUP_ON, target: Hue::Light.find("l1")).valid?
    assert binding(ControlBinding::WEBHOOK, target: nil, settings: { url: "http://hooks.test" }).valid?
  end

  test "the cycle window defaults to ten seconds" do
    assert_equal 10.seconds, binding(ControlBinding::CYCLE_SCENES).cycle_window
    assert_equal 4.seconds, binding(ControlBinding::CYCLE_SCENES, settings: { "cycle_window_s" => 4 }).cycle_window
  end
end

class CycleStateTest < ActiveSupport::TestCase
  setup { Hue::Mirror::Sync.call }

  test "walks the steps, wraps, and restarts after the idle window" do
    cycle_binding = ControlBinding.create!(control: Hue::Control.find("b1"), gesture: ControlBinding::SHORT_RELEASE,
      action: ControlBinding::CYCLE_SCENES, target: Hue::Group.find("z1"), settings: { ControlBinding::CYCLE_WINDOW_SETTING => 10 })
    cycle_binding.replace_steps!([ Hue::Scene.find("s1"), Hue::Scene.find("s2"), CustomScene.create!(name: "Mine") ])
    cycle = cycle_binding.create_cycle_state!
    start = Time.current

    assert_equal "Relax", cycle.advance!(at: start).scene.name
    assert_equal "Bright", cycle.advance!(at: start + 2).scene.name
    assert_equal "Mine", cycle.upcoming_step(at: start + 3).scene.name
    assert_equal "Mine", cycle.advance!(at: start + 4).scene.name
    assert_equal "Relax", cycle.advance!(at: start + 6).scene.name, "wraps around"
    assert_equal "Relax", cycle.advance!(at: start + 30).scene.name, "idle for longer than the window restarts the cycle"
  end
end

class CustomSceneTest < ActiveSupport::TestCase
  setup { Hue::Mirror::Sync.call }

  def scene_light(**attributes)
    CustomScene.create!(name: "Now").lights.build(hue_light: Hue::Light.find("l1"), **attributes)
  end

  test "a scene light can have a colour or a mirek" do
    assert scene_light(color_x: 0.3, color_y: 0.3).valid?
    assert scene_light(mirek: 366).valid?
    assert scene_light.valid?
  end

  test "a scene light cannot have both a colour and a mirek" do
    refute scene_light(color_x: 0.3, color_y: 0.3, mirek: 366).valid?
  end
end
