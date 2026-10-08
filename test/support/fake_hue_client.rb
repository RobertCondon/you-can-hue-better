# In-memory stand-in for Hue::Client. Holds the same JSON shapes the bridge returns
# and records every write so tests can assert on what the app sent.
class FakeHueClient
  attr_reader :writes

  def initialize
    @writes = []
    @lights = {
      "l1" => light_json("l1", "Desk lamp", on: true, bri: 80.0, xy: { "x" => 0.4529, "y" => 0.4089 }, device: "d1", v1: 7),
      "l2" => light_json("l2", "Corner lamp", on: false, bri: 0.0, xy: { "x" => 0.3, "y" => 0.3 }, device: "d2", v1: 8)
    }
  end

  def lights  = @lights.values
  def light(id) = @lights.fetch(id)
  def rooms   = [ group_json("r1", "Study", children: [ { "rid" => "d1", "rtype" => "device" }, { "rid" => "d2", "rtype" => "device" } ], grouped: "g1", v1: 82) ]
  def zones   = [ group_json("z1", "Evening", children: [ { "rid" => "l1", "rtype" => "light" } ], grouped: "g2", v1: 85) ]
  def scenes
    [ scene_json("s1", "Relax", "r1", "AAA", lights: %w[l1 l2], palette: [ [ 0.5, 0.4 ], [ 0.3, 0.3 ] ], image: "img-relax"),
      scene_json("s2", "Bright", "r1", "BBB", lights: %w[l1 l2], palette: [], image: "img-bright"),
      scene_json("s3", "Dusk", "z1", "CCC", lights: %w[l1], palette: [ [ 0.6, 0.35 ] ], image: "img-relax") ]
  end
  def smart_scenes = [ { "id" => "ss1", "metadata" => { "name" => "Natural light" }, "group" => { "rid" => "r1", "rtype" => "room" } } ]
  def devices = [ device_json("d1", "Desk lamp", "Hue color lamp", light: "l1", v1: "/lights/7"),
                  device_json("d2", "Corner lamp", "Hue color lamp", light: "l2", v1: "/lights/8"),
                  { "id" => "d3", "id_v1" => "/sensors/18", "metadata" => { "name" => "Dial" }, "product_data" => { "product_name" => "Hue tap dial switch" },
                    "services" => [ { "rid" => "b1", "rtype" => "button" }, { "rid" => "b2", "rtype" => "button" }, { "rid" => "rot", "rtype" => "relative_rotary" } ] } ]
  def grouped_lights = [ grouped_json("g1", "r1", "room", on: true, bri: 40.0), grouped_json("g2", "z1", "zone", on: true, bri: 80.0),
                         grouped_json("g0", "home1", "bridge_home", on: true, bri: 40.0) ]
  def buttons = [ button_json("b1", "d3", 1, "/sensors/18"), button_json("b2", "d3", 2, "/sensors/18") ]
  def rotaries = [ { "id" => "rot", "id_v1" => "/sensors/17", "owner" => { "rid" => "d3", "rtype" => "device" },
                     "relative_rotary" => { "rotary_report" => { "action" => "repeat", "updated" => "2026-10-05T08:48:50Z" } } } ]
  def zigbee_connectivity = [ { "id" => "zc1", "owner" => { "rid" => "d2", "rtype" => "device" }, "status" => "connectivity_issue" } ]
  def device_power = [ { "id" => "dp1", "owner" => { "rid" => "d3", "rtype" => "device" }, "power_state" => { "battery_level" => 87 } } ]

  def set_light(id, body)
    @writes << [ :light, id, body ]
    l = @lights.fetch(id)
    l["on"]["on"] = body[:on][:on] if body[:on]
    l["dimming"]["brightness"] = body[:dimming][:brightness] if body[:dimming]
    l["color"]["xy"] = body[:color][:xy].transform_keys(&:to_s) if body[:color]
    { "data" => [ { "rid" => id, "rtype" => "light" } ], "errors" => [] }
  end

  def set_grouped_light(id, body)
    @writes << [ :grouped_light, id, body ]
    @lights.each_value { _1["on"]["on"] = body[:on][:on] } if body[:on]
    { "data" => [], "errors" => [] }
  end

  def recall_scene(id, action: "active")
    @writes << [ :scene, id, action ]
    { "data" => [], "errors" => [] }
  end

  def rename_light(id, name)
    raise Hue::Error, "json-schema validation: maxLength 32" if name.length > 32
    @writes << [ :rename_light, id, name ]
    @lights.fetch(id)["metadata"]["name"] = name
    { "data" => [ { "rid" => id, "rtype" => "light" } ], "errors" => [] }
  end

  def rename_device(id, name)
    @writes << [ :rename_device, id, name ]
    { "data" => [ { "rid" => id, "rtype" => "device" } ], "errors" => [] }
  end

  def rename_group(kind, id, name)
    raise Hue::Error, "json-schema validation: maxLength 32" if name.length > 32
    @writes << [ :rename_group, kind, id, name ]
    { "data" => [ { "rid" => id, "rtype" => kind } ], "errors" => [] }
  end

  private

  def light_json(id, name, on:, bri:, xy:, device:, v1:)
    { "type" => "light", "id" => id, "id_v1" => "/lights/#{v1}", "metadata" => { "name" => name }, "on" => { "on" => on },
      "dimming" => { "brightness" => bri }, "color" => { "xy" => xy, "gamut" => { "red" => { "x" => 0.6915, "y" => 0.3083 }, "green" => { "x" => 0.17, "y" => 0.7 }, "blue" => { "x" => 0.1532, "y" => 0.0475 } } },
      "color_temperature" => { "mirek" => 359, "mirek_valid" => true },
      "owner" => { "rid" => device, "rtype" => "device" } }
  end

  def group_json(id, name, children:, grouped:, v1:)
    { "id" => id, "id_v1" => "/groups/#{v1}", "metadata" => { "name" => name }, "children" => children,
      "services" => [ { "rid" => grouped, "rtype" => "grouped_light" } ] }
  end

  def grouped_json(id, owner, rtype, on:, bri:)
    { "type" => "grouped_light", "id" => id, "owner" => { "rid" => owner, "rtype" => rtype }, "on" => { "on" => on }, "dimming" => { "brightness" => bri } }
  end

  def scene_json(id, name, group, v1, lights:, palette:, image:)
    actions = lights.each_with_index.map do |l, i|
      act = i.even? ? { "color" => { "xy" => { "x" => 0.5, "y" => 0.4 } } } : { "color_temperature" => { "mirek" => 400 } }
      { "target" => { "rid" => l, "rtype" => "light" }, "action" => { "on" => { "on" => true }, "dimming" => { "brightness" => 38.0 } }.merge(act) }
    end
    { "type" => "scene", "id" => id, "id_v1" => "/scenes/#{v1}", "metadata" => { "name" => name, "image" => { "rid" => image, "rtype" => "public_image" } },
      "group" => { "rid" => group, "rtype" => "room" }, "actions" => actions,
      "palette" => { "color" => palette.map { |x, y| { "color" => { "xy" => { "x" => x, "y" => y } }, "dimming" => { "brightness" => 38.0 } } },
                     "color_temperature" => [], "dimming" => [], "effects" => [] },
      "speed" => 0.5, "auto_dynamic" => false, "status" => { "active" => "inactive" }, "last_actions_update" => "2026-10-01T00:00:00Z" }
  end

  def device_json(id, name, product, light:, v1:)
    { "id" => id, "id_v1" => v1, "metadata" => { "name" => name }, "product_data" => { "product_name" => product },
      "services" => [ { "rid" => light, "rtype" => "light" } ] }
  end

  def button_json(id, device, number, v1)
    { "type" => "button", "id" => id, "id_v1" => v1, "owner" => { "rid" => device, "rtype" => "device" }, "metadata" => { "control_id" => number },
      "button" => { "button_report" => { "event" => "short_release", "updated" => "2026-10-06T05:33:51Z" } } }
  end
end
