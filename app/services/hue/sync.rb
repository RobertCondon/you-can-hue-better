module Hue
  # Full rebuild of the mirror tables from the bridge. Idempotent: rows are upserted by Hue id and
  # anything the bridge no longer reports is removed. The event listener (later) keeps rows fresh
  # between runs; this is the baseline it starts from.
  class Sync
    RESOURCES = %i[devices lights rooms zones grouped_lights scenes smart_scenes buttons relative_rotaries zigbee_connectivity device_power].freeze

    def self.run(client = Hue.client) = new(client).run

    def initialize(client)
      @client = client
    end

    def run
      @r = RESOURCES.index_with { |name| @client.public_send(name).all }
      Record.transaction do
        devices  = sync_devices
        lights   = sync_lights
        groups   = sync_groups
        sync_memberships
        scenes   = sync_scenes
        controls = sync_controls
        prune(Scene => scenes, Control => controls, Light => lights, Group => groups, Device => devices)
        ListenerState.current.update!(full_sync_at: Time.current)
      end
      { devices: Device.count, lights: Light.count, groups: Group.count, scenes: Scene.count, controls: Control.count }
    end

    private

    def by_owner(name) = @r[name].index_by { _1.dig("owner", "rid") }

    def sync_devices
      reach = by_owner(:zigbee_connectivity)
      power = by_owner(:device_power)
      @r[:devices].map do |d|
        has_light = d["services"].any? { _1["rtype"] == "light" }
        upsert(Device, d["id"],
          name: d.dig("metadata", "name"), product_name: d.dig("product_data", "product_name"),
          kind: Device.kind_for(d.dig("product_data", "product_name"), has_light:), id_v1: d["id_v1"],
          reachable: reach[d["id"]].nil? || reach[d["id"]]["status"] == "connected",
          battery_percent: power[d["id"]]&.dig("power_state", "battery_level"), raw: d)
      end
    end

    def sync_lights
      @r[:lights].map do |l|
        upsert(Light, l["id"],
          device_id: l.dig("owner", "rid"), name: l.dig("metadata", "name"), id_v1: l["id_v1"],
          on: l.dig("on", "on"), brightness: l.dig("dimming", "brightness") || 0,
          color_x: l.dig("color", "xy", "x"), color_y: l.dig("color", "xy", "y"),
          mirek: l.dig("color_temperature", "mirek"), raw: l)
      end
    end

    def sync_groups
      grouped = by_owner(:grouped_lights)
      rows = @r[:rooms].map { [ _1, "room" ] } + @r[:zones].map { [ _1, "zone" ] }
      ids = rows.map do |g, kind|
        gl = grouped[g["id"]]
        upsert(Group, g["id"], kind:, name: g.dig("metadata", "name"), id_v1: g["id_v1"],
          grouped_light_id: gl&.dig("id"), any_on: gl&.dig("on", "on") || false,
          brightness: gl&.dig("dimming", "brightness") || 0, raw: g)
      end
      home = @r[:grouped_lights].find { _1.dig("owner", "rtype") == "bridge_home" }
      if home
        ids << upsert(Group, home.dig("owner", "rid"), kind: "home", name: "Home", id_v1: home["id_v1"],
          grouped_light_id: home["id"], any_on: home.dig("on", "on") || false,
          brightness: home.dig("dimming", "brightness") || 0, raw: home)
      end
      ids
    end

    # Rooms contain devices (whose services include lights); zones contain lights; home has all.
    def sync_memberships
      device_lights = @r[:devices].to_h { |d| [ d["id"], d["services"].select { _1["rtype"] == "light" }.map { _1["rid"] } ] }
      known = Light.pluck(:id).to_set
      pairs = @r[:rooms].flat_map { |g| g["children"].flat_map { device_lights[_1["rid"]] || [] }.map { [ g["id"], _1 ] } } +
              @r[:zones].flat_map { |g| g["children"].select { _1["rtype"] == "light" }.map { [ g["id"], _1["rid"] ] } }
      Group.where(kind: "home").pluck(:id).each { |h| pairs += known.map { [ h, _1 ] } }
      pairs = pairs.select { |_, l| known.include?(l) }.uniq

      GroupLight.delete_all
      GroupLight.insert_all(pairs.map { |g, l| { group_id: g, light_id: l } }) if pairs.any?
    end

    def sync_scenes
      groups = Group.pluck(:id).to_set
      rows = @r[:scenes].map { [ _1, "scene" ] } + @r[:smart_scenes].map { [ _1, "smart_scene" ] }
      rows.filter_map do |s, kind|
        next unless groups.include?(s.dig("group", "rid"))
        scene = Scene.find_or_initialize_by(id: s["id"])
        scene.assign_attributes(group_id: s.dig("group", "rid"), name: s.dig("metadata", "name"), kind:, id_v1: s["id_v1"])
        scene.assign_from_raw(s)
        scene.save! if scene.changed?
        scene.rebuild_actions! if kind == "scene"
        scene.id
      end
    end

    def sync_controls
      buttons = @r[:buttons].map do |b|
        report = b.dig("button", "button_report") || {}
        upsert(Control, b["id"], device_id: b.dig("owner", "rid"), kind: "button",
          control_number: b.dig("metadata", "control_id"), id_v1: b["id_v1"],
          last_event: report["event"], last_event_at: report["updated"])
      end
      rotaries = @r[:relative_rotaries].map do |r|
        report = r.dig("relative_rotary", "rotary_report") || {}
        upsert(Control, r["id"], device_id: r.dig("owner", "rid"), kind: "rotary", id_v1: r["id_v1"],
          last_event: report["action"], last_event_at: report["updated"])
      end
      buttons + rotaries
    end

    def upsert(model, id, attrs)
      record = model.find_or_initialize_by(id:)
      record.assign_attributes(attrs)
      record.save! if record.changed?
      id
    end

    def prune(keep)
      keep.each { |model, ids| model.where.not(id: ids).find_each(&:destroy!) }
    end
  end
end
