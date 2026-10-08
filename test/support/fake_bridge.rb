require "net/http"

class FakeBridge
  MAX_NAME_LENGTH = 32
  RESOURCE_PATH = %r{\A#{Hue::Resources::Resource::RESOURCE_ROOT}/(?<resource_type>[a-z_]+)(?:/(?<resource_id>[^/]+))?\z}
  UNPOWERED_LIGHT_ERROR = "device (light) has communication issues, command may not have effect"
  RENAME_WRITE_KINDS = { Hue::ResourceType::LIGHT => :rename_light, Hue::ResourceType::DEVICE => :rename_device }.freeze

  attr_reader :writes, :unpowered_light_ids
  attr_accessor :rejection_for_writes

  def initialize
    @resources = seed_resources
    @writes = []
    @unpowered_light_ids = []
  end

  def get(path)
    resource_type, resource_id = parse(path)
    matching = @resources.fetch(resource_type, [])
    matching = matching.select { |resource| resource["id"] == resource_id } if resource_id
    reply(data: matching)
  end

  def put(path, changes)
    return reply(errors: [ { description: rejection_for_writes } ]) if rejection_for_writes

    resource_type, resource_id = parse(path)
    new_name = changes.dig(:metadata, :name)
    return reply(errors: [ { description: "json-schema validation: maxLength #{MAX_NAME_LENGTH}" } ]) if new_name.to_s.length > MAX_NAME_LENGTH

    new_name ? record_rename(resource_type, resource_id, new_name) : record_change(resource_type, resource_id, changes)
    unpowered = resource_type == Hue::ResourceType::LIGHT && @unpowered_light_ids.include?(resource_id)
    reply(errors: unpowered ? [ { description: UNPOWERED_LIGHT_ERROR } ] : [])
  end

  private

  def parse(path)
    match = RESOURCE_PATH.match(path) or raise ArgumentError, "not a resource path: #{path}"
    [ match[:resource_type], match[:resource_id] ]
  end

  def resource(resource_type, resource_id)
    @resources.fetch(resource_type).find { |candidate| candidate["id"] == resource_id } or raise ArgumentError, "no #{resource_type} #{resource_id}"
  end

  def record_rename(resource_type, resource_id, name)
    @writes << (RENAME_WRITE_KINDS[resource_type] ? [ RENAME_WRITE_KINDS[resource_type], resource_id, name ] : [ :rename_group, resource_type, resource_id, name ])
    resource(resource_type, resource_id)["metadata"]["name"] = name
  end

  def record_change(resource_type, resource_id, changes)
    case resource_type
    when Hue::ResourceType::SCENE
      @writes << [ :scene, resource_id, changes.dig(:recall, :action) ]
    when Hue::ResourceType::GROUPED_LIGHT
      @writes << [ :grouped_light, resource_id, changes ]
      @resources[Hue::ResourceType::LIGHT].each { |light| light["on"]["on"] = changes[:on][:on] } if changes[:on]
    when Hue::ResourceType::LIGHT
      @writes << [ :light, resource_id, changes ]
      apply_light_changes(resource(resource_type, resource_id), changes)
    end
  end

  def apply_light_changes(light, changes)
    light["on"]["on"] = changes[:on][:on] if changes[:on]
    light["dimming"]["brightness"] = changes[:dimming][:brightness] if changes[:dimming]
    light["color"]["xy"] = changes[:color][:xy].transform_keys(&:to_s) if changes[:color]
  end

  def reply(data: [], errors: [])
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, { data:, errors: }.to_json)
    end
  end

  def seed_resources
    {
      Hue::ResourceType::LIGHT => [
        light_json("l1", "Desk lamp", on: true, bri: 80.0, xy: { "x" => 0.4529, "y" => 0.4089 }, device: "d1", v1: 7),
        light_json("l2", "Corner lamp", on: false, bri: 0.0, xy: { "x" => 0.3, "y" => 0.3 }, device: "d2", v1: 8)
      ],
      Hue::ResourceType::ROOM => [ group_json("r1", "Study", children: [ { "rid" => "d1", "rtype" => "device" }, { "rid" => "d2", "rtype" => "device" } ], grouped: "g1", v1: 82) ],
      Hue::ResourceType::ZONE => [ group_json("z1", "Evening", children: [ { "rid" => "l1", "rtype" => "light" } ], grouped: "g2", v1: 85) ],
      Hue::ResourceType::SCENE => [
        scene_json("s1", "Relax", "r1", "AAA", lights: %w[l1 l2], palette: [ [ 0.5, 0.4 ], [ 0.3, 0.3 ] ], image: "img-relax"),
        scene_json("s2", "Bright", "r1", "BBB", lights: %w[l1 l2], palette: [], image: "img-bright"),
        scene_json("s3", "Dusk", "z1", "CCC", lights: %w[l1], palette: [ [ 0.6, 0.35 ] ], image: "img-relax")
      ],
      Hue::ResourceType::SMART_SCENE => [ { "id" => "ss1", "metadata" => { "name" => "Natural light" }, "group" => { "rid" => "r1", "rtype" => "room" } } ],
      Hue::ResourceType::DEVICE => [
        device_json("d1", "Desk lamp", "Hue color lamp", light: "l1", v1: "/lights/7"),
        device_json("d2", "Corner lamp", "Hue color lamp", light: "l2", v1: "/lights/8"),
        { "id" => "d3", "id_v1" => "/sensors/18", "metadata" => { "name" => "Dial" }, "product_data" => { "product_name" => "Hue tap dial switch" },
          "services" => [ { "rid" => "b1", "rtype" => "button" }, { "rid" => "b2", "rtype" => "button" }, { "rid" => "rot", "rtype" => "relative_rotary" } ] }
      ],
      Hue::ResourceType::GROUPED_LIGHT => [
        grouped_json("g1", "r1", "room", on: true, bri: 40.0),
        grouped_json("g2", "z1", "zone", on: true, bri: 80.0),
        grouped_json("g0", "home1", "bridge_home", on: true, bri: 40.0)
      ],
      Hue::ResourceType::BUTTON => [ button_json("b1", "d3", 1, "/sensors/18"), button_json("b2", "d3", 2, "/sensors/18") ],
      Hue::ResourceType::RELATIVE_ROTARY => [ { "id" => "rot", "id_v1" => "/sensors/17", "owner" => { "rid" => "d3", "rtype" => "device" },
                                                 "relative_rotary" => { "rotary_report" => { "action" => "repeat", "updated" => "2026-10-05T08:48:50Z" } } } ],
      Hue::ResourceType::ZIGBEE_CONNECTIVITY => [ { "id" => "zc1", "owner" => { "rid" => "d2", "rtype" => "device" }, "status" => "connectivity_issue" } ],
      Hue::ResourceType::DEVICE_POWER => [ { "id" => "dp1", "owner" => { "rid" => "d3", "rtype" => "device" }, "power_state" => { "battery_level" => 87 } } ]
    }
  end

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
