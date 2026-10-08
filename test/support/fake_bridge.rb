require "net/http"

class FakeBridge
  MAX_NAME_LENGTH = 32
  RESOURCE_PATH = %r{\A#{Hue::Api::Resources::Resource::RESOURCE_ROOT}/(?<resource_type>[a-z_]+)(?:/(?<resource_id>[^/]+))?\z}
  UNPOWERED_LIGHT_ERROR = "device (light) has communication issues, command may not have effect"
  RENAME_WRITE_KINDS = { Hue::Api::ResourceType::LIGHT => :rename_light, Hue::Api::ResourceType::DEVICE => :rename_device }.freeze

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
    unpowered = resource_type == Hue::Api::ResourceType::LIGHT && @unpowered_light_ids.include?(resource_id)
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
    when Hue::Api::ResourceType::SCENE
      @writes << [ :scene, resource_id, changes.dig(:recall, :action) ]
    when Hue::Api::ResourceType::GROUPED_LIGHT
      @writes << [ :grouped_light, resource_id, changes ]
      @resources[Hue::Api::ResourceType::LIGHT].each { |light| light["on"]["on"] = changes[:on][:on] } if changes[:on]
    when Hue::Api::ResourceType::LIGHT
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
      Hue::Api::ResourceType::LIGHT => [
        light_json("l1", "Desk lamp", on: true, brightness: 80.0, xy: { "x" => 0.4529, "y" => 0.4089 }, device: "d1", legacy_number: 7),
        light_json("l2", "Corner lamp", on: false, brightness: 0.0, xy: { "x" => 0.3, "y" => 0.3 }, device: "d2", legacy_number: 8)
      ],
      Hue::Api::ResourceType::ROOM => [ group_json("r1", "Study", children: [ { "rid" => "d1", "rtype" => "device" }, { "rid" => "d2", "rtype" => "device" } ], grouped_light: "g1", legacy_number: 82) ],
      Hue::Api::ResourceType::ZONE => [ group_json("z1", "Evening", children: [ { "rid" => "l1", "rtype" => "light" } ], grouped_light: "g2", legacy_number: 85) ],
      Hue::Api::ResourceType::SCENE => [
        scene_json("s1", "Relax", "r1", "AAA", lights: %w[l1 l2], palette: [ [ 0.5, 0.4 ], [ 0.3, 0.3 ] ], image: "img-relax"),
        scene_json("s2", "Bright", "r1", "BBB", lights: %w[l1 l2], palette: [], image: "img-bright"),
        scene_json("s3", "Dusk", "z1", "CCC", lights: %w[l1], palette: [ [ 0.6, 0.35 ] ], image: "img-relax")
      ],
      Hue::Api::ResourceType::SMART_SCENE => [ { "id" => "ss1", "metadata" => { "name" => "Natural light" }, "group" => { "rid" => "r1", "rtype" => "room" } } ],
      Hue::Api::ResourceType::DEVICE => [
        device_json("d1", "Desk lamp", "Hue color lamp", light: "l1", legacy_id: "/lights/7"),
        device_json("d2", "Corner lamp", "Hue color lamp", light: "l2", legacy_id: "/lights/8"),
        { "id" => "d3", "id_v1" => "/sensors/18", "metadata" => { "name" => "Dial" }, "product_data" => { "product_name" => "Hue tap dial switch" },
          "services" => [ { "rid" => "b1", "rtype" => "button" }, { "rid" => "b2", "rtype" => "button" }, { "rid" => "rot", "rtype" => "relative_rotary" } ] }
      ],
      Hue::Api::ResourceType::GROUPED_LIGHT => [
        grouped_json("g1", "r1", "room", on: true, brightness: 40.0),
        grouped_json("g2", "z1", "zone", on: true, brightness: 80.0),
        grouped_json("g0", "home1", "bridge_home", on: true, brightness: 40.0)
      ],
      Hue::Api::ResourceType::BUTTON => [ button_json("b1", "d3", 1, "/sensors/18"), button_json("b2", "d3", 2, "/sensors/18") ],
      Hue::Api::ResourceType::RELATIVE_ROTARY => [ { "id" => "rot", "id_v1" => "/sensors/17", "owner" => { "rid" => "d3", "rtype" => "device" },
                                                 "relative_rotary" => { "rotary_report" => { "action" => "repeat", "updated" => "2026-10-05T08:48:50Z" } } } ],
      Hue::Api::ResourceType::ZIGBEE_CONNECTIVITY => [ { "id" => "zc1", "owner" => { "rid" => "d2", "rtype" => "device" }, "status" => "connectivity_issue" } ],
      Hue::Api::ResourceType::DEVICE_POWER => [ { "id" => "dp1", "owner" => { "rid" => "d3", "rtype" => "device" }, "power_state" => { "battery_level" => 87 } } ]
    }
  end

  def light_json(id, name, on:, brightness:, xy:, device:, legacy_number:)
    { "type" => "light", "id" => id, "id_v1" => "/lights/#{legacy_number}", "metadata" => { "name" => name }, "on" => { "on" => on },
      "dimming" => { "brightness" => brightness },
      "color" => { "xy" => xy, "gamut" => { "red" => { "x" => 0.6915, "y" => 0.3083 }, "green" => { "x" => 0.17, "y" => 0.7 }, "blue" => { "x" => 0.1532, "y" => 0.0475 } } },
      "color_temperature" => { "mirek" => 359, "mirek_valid" => true },
      "owner" => { "rid" => device, "rtype" => "device" } }
  end

  def group_json(id, name, children:, grouped_light:, legacy_number:)
    { "id" => id, "id_v1" => "/groups/#{legacy_number}", "metadata" => { "name" => name }, "children" => children,
      "services" => [ { "rid" => grouped_light, "rtype" => "grouped_light" } ] }
  end

  def grouped_json(id, owner, owner_type, on:, brightness:)
    { "type" => "grouped_light", "id" => id, "owner" => { "rid" => owner, "rtype" => owner_type }, "on" => { "on" => on }, "dimming" => { "brightness" => brightness } }
  end

  def scene_json(id, name, group, legacy_id, lights:, palette:, image:)
    actions = lights.each_with_index.map do |light_id, position|
      colour = position.even? ? { "color" => { "xy" => { "x" => 0.5, "y" => 0.4 } } } : { "color_temperature" => { "mirek" => 400 } }
      { "target" => { "rid" => light_id, "rtype" => "light" }, "action" => { "on" => { "on" => true }, "dimming" => { "brightness" => 38.0 } }.merge(colour) }
    end
    { "type" => "scene", "id" => id, "id_v1" => "/scenes/#{legacy_id}", "metadata" => { "name" => name, "image" => { "rid" => image, "rtype" => "public_image" } },
      "group" => { "rid" => group, "rtype" => "room" }, "actions" => actions,
      "palette" => { "color" => palette.map { |palette_x, palette_y| { "color" => { "xy" => { "x" => palette_x, "y" => palette_y } }, "dimming" => { "brightness" => 38.0 } } },
                     "color_temperature" => [], "dimming" => [], "effects" => [] },
      "speed" => 0.5, "auto_dynamic" => false, "status" => { "active" => "inactive" }, "last_actions_update" => "2026-10-01T00:00:00Z" }
  end

  def device_json(id, name, product, light:, legacy_id:)
    { "id" => id, "id_v1" => legacy_id, "metadata" => { "name" => name }, "product_data" => { "product_name" => product },
      "services" => [ { "rid" => light, "rtype" => "light" } ] }
  end

  def button_json(id, device, number, legacy_id)
    { "type" => "button", "id" => id, "id_v1" => legacy_id, "owner" => { "rid" => device, "rtype" => "device" }, "metadata" => { "control_id" => number },
      "button" => { "button_report" => { "event" => "short_release", "updated" => "2026-10-06T05:33:51Z" } } }
  end
end
