require "test_helper"

class LegacyRulesImportTest < ActiveSupport::TestCase
  setup { Hue::Mirror::Sync.call }

  def rules = {
    "1" => rule([ cond("/sensors/18/state/buttonevent", "eq", "1000"), cond("/sensors/22/state/status", "eq", "0") ],
                [ act("/sensors/22/state", { "status" => 1 }), act("/groups/85/action", { "scene" => "CCC" }) ]),
    "2" => rule([ cond("/sensors/18/state/buttonevent", "eq", "1000"), cond("/sensors/22/state/status", "eq", "1") ],
                [ act("/sensors/22/state", { "status" => 2 }), act("/groups/85/action", { "scene" => "AAA" }) ]),
    "3" => rule([ cond("/sensors/18/state/buttonevent", "eq", "1000"), cond("/sensors/22/state/status", "eq", "2") ],
                [ act("/sensors/22/state", { "status" => 0 }), act("/groups/85/action", { "scene" => "MISSING" }) ]),
    "4" => rule([ cond("/sensors/18/state/buttonevent", "eq", "1001") ], [ act("/groups/85/action", { "on" => false }) ]),
    "5" => rule([ cond("/sensors/18/state/buttonevent", "eq", "2000") ], [ act("/sensors/8/state", { "status" => 1 }) ]),
    "6" => rule([ cond("/sensors/8/state/status", "eq", "1"), cond("/groups/82/state/any_on", "eq", "true") ], [ act("/groups/82/action", { "on" => false }) ]),
    "7" => rule([ cond("/sensors/8/state/status", "eq", "1"), cond("/groups/82/state/any_on", "eq", "false") ], [ act("/groups/82/action", { "on" => true }) ]),
    "8" => rule([ cond("/sensors/18/state/buttonevent", "eq", "2001") ], [ act("/groups/82/action", { "bri_inc" => -56, "transitiontime" => 9 }) ]),
    "9"  => rule([ cond("/sensors/17/state/expectedrotation", "gt", "1"), cond("/sensors/17/state/expectedrotation", "lt", "19"), cond("/groups/85/state/any_on", "eq", "true") ], [ act("/groups/85/action", { "bri_inc" => 6, "transitiontime" => 4 }) ]),
    "10" => rule([ cond("/sensors/17/state/expectedrotation", "gt", "18"), cond("/groups/85/state/any_on", "eq", "true") ], [ act("/groups/85/action", { "bri_inc" => 254, "transitiontime" => 2 }) ]),
    "11" => rule([ cond("/sensors/17/state/expectedrotation", "gt", "-20"), cond("/sensors/17/state/expectedrotation", "lt", "-2"), cond("/groups/85/state/any_on", "eq", "true") ], [ act("/groups/85/action", { "bri_inc" => -6, "transitiontime" => 4 }) ]),
    "12" => rule([ cond("/sensors/17/state/expectedrotation", "gt", "126"), cond("/groups/85/state/any_on", "eq", "false") ], [ act("/groups/85/action", { "on" => true, "bri" => 127 }) ]),
    "13" => rule([ cond("/sensors/17/state/expectedrotation", "lt", "127"), cond("/groups/85/state/any_on", "eq", "false") ], [ act("/groups/85/action", { "on" => true, "bri" => 4 }) ]),
    "14" => rule([ cond("/sensors/18/state/lastupdated", "ddx", nil) ], [ act("/sensors/22/state", { "status" => 0 }) ])
  }

  test "imports cycles, toggles, holds and rotary bands" do
    result = LegacyRulesImport.call(rules)
    assert_empty result.skipped
    first_button = Hue::Control.find("b1")
    second_button = Hue::Control.find("b2")
    ring = Hue::Control.find("rot")
    zone = Hue::Group.find("z1")
    study = Hue::Group.find("r1")

    cycle = first_button.bindings.find_by!(gesture: "short_release")
    assert_equal "cycle_scenes", cycle.action
    assert_equal zone, cycle.target
    assert_equal %w[Dusk Relax], cycle.scenes.map(&:name), "unknown scene ids are dropped, order kept"

    hold_off = first_button.bindings.find_by!(gesture: "long_press")
    assert_equal [ "group_off", zone ], [ hold_off.action, hold_off.target ]
    toggle = second_button.bindings.find_by!(gesture: "short_release")
    assert_equal [ "toggle_group", study ], [ toggle.action, toggle.target ]

    dim = second_button.bindings.find_by!(gesture: "repeat")
    assert_equal "brightness_delta", dim.action
    assert_equal({ "delta" => -22.0, "transition_ms" => 900 }, dim.settings)

    clockwise = ring.bindings.find_by!(gesture: "rotate_cw")
    assert_equal [ { "min_steps" => 2, "delta" => 2.4, "transition_ms" => 400 }, { "min_steps" => 19, "delta" => 100.0, "transition_ms" => 200 } ], clockwise.settings["bands"]
    assert_equal({ "fast" => { "brightness" => 50.0, "min_steps" => 127 }, "slow" => { "brightness" => 1.6, "min_steps" => 0 } }, clockwise.settings["on_if_off"])
    counter_clockwise = ring.bindings.find_by!(gesture: "rotate_ccw")
    assert_equal [ { "min_steps" => 3, "delta" => 2.4, "transition_ms" => 400 } ], counter_clockwise.settings["bands"]
  end

  test "a press on a button the mirror doesn't know is skipped with the reason" do
    unknown_button = { "99" => rule([ cond("/sensors/404/state/buttonevent", "eq", "1000") ], [ act("/groups/85/action", { "on" => false }) ]) }
    result = LegacyRulesImport.call(unknown_button)
    assert_empty result.bindings
    assert_equal [ LegacyRulesImport::Outcome::Skip.new(rule_ids: [ "99" ], reason: "no control for /sensors/404 button 1") ], result.skipped
  end

  test "running twice updates rather than duplicates" do
    LegacyRulesImport.call(rules)
    LegacyRulesImport.call(rules)
    assert_equal 6, ControlBinding.count
    assert_equal 2, ControlBinding.find_by!(gesture: "short_release", control_id: "b1").steps.count
  end

  def rule(conditions, actions) = { "name" => "r", "status" => "enabled", "conditions" => conditions, "actions" => actions }
  def cond(address, operator, value) = { "address" => address, "operator" => operator, "value" => value }.compact
  def act(address, body) = { "address" => address, "method" => "PUT", "body" => body }
end
