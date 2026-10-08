require "test_helper"

class Hue::MirrorTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "a partial light event touches only the fields it carries" do
    changes = Hue::Mirror.apply([ { "type" => "light", "id" => "l1", "dimming" => { "brightness" => 12.5 } } ])
    l = Hue::Light.find("l1")
    assert_equal 12.5, l.brightness.to_f
    assert l.on, "on was not in the event, so it is untouched"
    assert_in_delta 0.4529, l.color_x.to_f, 0.0001
    assert_equal [ "l1" ], changes.light_ids
    assert_equal 12.5, l.raw.dig("dimming", "brightness")
  end

  test "an unchanged event reports no change" do
    changes = Hue::Mirror.apply([ { "type" => "light", "id" => "l1", "on" => { "on" => true } } ])
    assert_empty changes.light_ids
  end

  test "grouped_light events update the group aggregates" do
    changes = Hue::Mirror.apply([ { "type" => "grouped_light", "id" => "g1", "on" => { "on" => false }, "dimming" => { "brightness" => 0 } } ])
    assert_equal [ "r1" ], changes.group_ids
    refute Hue::Group.find("r1").any_on
  end

  test "a button event is logged once, even when the bridge replays it" do
    event = { "type" => "button", "id" => "b1", "button" => { "button_report" => { "event" => "short_release", "updated" => "2026-10-06T10:00:00Z" } } }
    first  = Hue::Mirror.apply([ event ], event_id: "evt-1", occurred_at: "2026-10-06T10:00:00Z")
    second = Hue::Mirror.apply([ event ], event_id: "evt-1", occurred_at: "2026-10-06T10:00:00Z")
    assert_equal 1, first.presses.size
    assert_empty second.presses
    assert_equal 1, ControlEvent.count
    e = ControlEvent.first
    assert_equal [ "b1", "short_release" ], [ e.control_id, e.gesture ]
    assert_equal "short_release", Hue::Control.find("b1").last_event
    assert_nil e.control_binding, "presses are logged, not acted on"
  end

  test "a rotary event records direction and steps" do
    event = { "type" => "relative_rotary", "id" => "rot", "relative_rotary" => { "rotary_report" => { "action" => "repeat", "updated" => "2026-10-06T10:00:00Z",
              "rotation" => { "direction" => "counter_clock_wise", "steps" => 30, "duration" => 400 } } } }
    Hue::Mirror.apply([ event ], event_id: "evt-2", occurred_at: "2026-10-06T10:00:00Z")
    e = ControlEvent.last
    assert_equal [ "rotate_ccw", 30, 400 ], [ e.gesture, e.rotation_steps, e.duration_ms ]
  end

  test "connectivity changes flip the device and flag its lights" do
    changes = Hue::Mirror.apply([ { "type" => "zigbee_connectivity", "id" => "zc9", "owner" => { "rid" => "d1", "rtype" => "device" }, "status" => "connectivity_issue" } ])
    refute Hue::Device.find("d1").reachable?
    assert_equal [ "l1" ], changes.light_ids
  end

  test "structural events ask for a full sync" do
    assert Hue::Mirror.apply([ { "type" => "scene", "id" => "new" } ]).structural
    assert Hue::Mirror.apply([ { "type" => "light", "id" => "unknown-light", "on" => { "on" => true } } ]).structural
  end

  test "refresh catches the mirror up from a GET" do
    Hue.client.lights.update("l2", { on: { on: true }, dimming: { brightness: 55 } })
    Hue::Mirror.refresh
    assert Hue::Light.find("l2").on
    assert_equal 55.0, Hue::Light.find("l2").brightness.to_f
  end
end

class Hue::MirrorSceneTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  test "a recall only changes the scene's status, with no full sync" do
    event = { "type" => "scene", "id" => "s1", "status" => { "active" => "dynamic_palette", "last_recall" => "2026-10-07T10:00:00Z" } }
    changes = Hue::Mirror.apply([ event ], event_id: "e1", occurred_at: "2026-10-07T10:00:00Z", kind: "update")
    refute changes.structural
    assert_equal [ "s1" ], changes.scene_ids
    s = Hue::Scene.find("s1")
    assert s.playing?
    assert_equal 2, s.actions.count, "actions untouched"
  end

  test "an edit to the scene's actions rebuilds its rows" do
    event = { "type" => "scene", "id" => "s1", "actions" => [ { "target" => { "rid" => "l1", "rtype" => "light" }, "action" => { "on" => { "on" => true }, "dimming" => { "brightness" => 90.0 }, "color_temperature" => { "mirek" => 200 } } } ] }
    Hue::Mirror.apply([ event ], kind: "update")
    s = Hue::Scene.find("s1")
    assert_equal 1, s.actions.count
    assert_equal [ 90.0, 200 ], [ s.actions.first.brightness.to_f, s.actions.first.mirek ]
  end

  test "a new or removed scene still asks for a full sync" do
    assert Hue::Mirror.apply([ { "type" => "scene", "id" => "new" } ], kind: "add").structural
    assert Hue::Mirror.apply([ { "type" => "scene", "id" => "s1" } ], kind: "delete").structural
  end
end
