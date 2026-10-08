module Hue
  # Applies bridge resources to the hue_* tables. Works for full resources (from a GET) and for the
  # partial diffs the event stream sends: only the fields present are touched.
  # Returns a Changes struct so the caller knows what to broadcast and whether a full sync is due.
  class Mirror
    Changes = Struct.new(:light_ids, :group_ids, :presses, :scene_ids, :structural) do
      def self.none = new([], [], [], [], false)
      def merge!(other)
        light_ids.concat(other.light_ids); group_ids.concat(other.group_ids); presses.concat(other.presses); scene_ids.concat(other.scene_ids)
        self.structural ||= other.structural
        self
      end
      def any? = light_ids.any? || group_ids.any? || presses.any? || scene_ids.any? || structural
    end

    STRUCTURAL = %w[device room zone smart_scene].freeze
    SCENE_DEFINITION_KEYS = %w[actions palette speed auto_dynamic metadata].freeze

    def self.apply(resources, event_id: nil, occurred_at: nil, kind: "update")
      resources.each_with_object(Changes.none) { |r, c| c.merge!(new(r, event_id:, occurred_at:, kind:).apply) }
    end

    # After a write, catch the mirror up without waiting for the stream: lights + group aggregates.
    def self.refresh(client = Hue.client)
      apply(client.lights.all + client.grouped_lights.all)
    end

    def initialize(resource, event_id:, occurred_at:, kind:)
      @r = resource
      @event_id = event_id
      @occurred_at = occurred_at
      @kind = kind
    end

    def apply
      changes = Changes.none
      case @r["type"]
      when "light"               then apply_light(changes)
      when "grouped_light"       then apply_grouped_light(changes)
      when "button"              then apply_button(changes)
      when "relative_rotary"     then apply_rotary(changes)
      when "zigbee_connectivity" then apply_connectivity(changes)
      when "device_power"        then apply_power(changes)
      when "scene"               then apply_scene(changes)
      when *STRUCTURAL           then changes.structural = true
      end
      changes
    end

    private

    def apply_light(changes)
      light = Light.find_by(id: @r["id"]) or return changes.structural = true
      attrs = {}
      attrs[:name]       = @r.dig("metadata", "name")      if @r.dig("metadata", "name")
      attrs[:on]         = @r.dig("on", "on")              unless @r.dig("on", "on").nil?
      attrs[:brightness] = @r.dig("dimming", "brightness") if @r.dig("dimming", "brightness")
      if (xy = @r.dig("color", "xy"))
        attrs[:color_x] = xy["x"]
        attrs[:color_y] = xy["y"]
      end
      attrs[:mirek] = @r.dig("color_temperature", "mirek") if @r.dig("color_temperature")&.key?("mirek")
      light.assign_attributes(attrs)
      return unless light.changed?
      light.raw = light.raw.deep_merge(@r)
      light.save!
      changes.light_ids << light.id
    end

    def apply_grouped_light(changes)
      group = Group.find_by(grouped_light_id: @r["id"]) or return
      attrs = {}
      attrs[:any_on]     = @r.dig("on", "on")              unless @r.dig("on", "on").nil?
      attrs[:brightness] = @r.dig("dimming", "brightness") if @r.dig("dimming", "brightness")
      group.assign_attributes(attrs)
      return unless group.changed?
      group.save!
      changes.group_ids << group.id
    end

    def apply_button(changes)
      report = @r.dig("button", "button_report") or return
      record_press(changes, gesture: report["event"], at: report["updated"])
    end

    def apply_rotary(changes)
      report = @r.dig("relative_rotary", "rotary_report") or return
      rotation = report["rotation"] || {}
      record_press(changes,
        gesture: rotation["direction"] == "counter_clock_wise" ? "rotate_ccw" : "rotate_cw",
        at: report["updated"], steps: rotation["steps"], direction: rotation["direction"], duration: rotation["duration"])
    end

    # Logged only. Nothing acts on presses yet; the bridge's own rules still drive the switches.
    def record_press(changes, gesture:, at:, steps: nil, direction: nil, duration: nil)
      control = Control.find_by(id: @r["id"]) or return changes.structural = true
      control.update_columns(last_event: gesture, last_event_at: at || Time.current)
      return unless @event_id

      event = ControlEvent.find_or_create_by!(control:, bridge_event_id: @event_id) do |e|
        e.gesture = gesture
        e.rotation_steps = steps
        e.rotation_direction = direction
        e.duration_ms = duration
        e.occurred_at = @occurred_at || at || Time.current
      end
      changes.presses << event if event.previously_new_record?
    end

    # Recalls change a scene's status many times a minute (every one, and continually while it
    # plays), so those are applied in place. Only adding or removing a scene needs a full sync.
    def apply_scene(changes)
      return changes.structural = true unless @kind == "update"
      scene = Scene.find_by(id: @r["id"]) or return changes.structural = true
      scene.assign_from_raw(scene.raw.deep_merge(@r))
      return unless scene.changed?
      scene.save!
      scene.rebuild_actions! if (@r.keys & SCENE_DEFINITION_KEYS).any?
      changes.scene_ids << scene.id
    end

    def apply_connectivity(changes)
      device = Device.find_by(id: @r.dig("owner", "rid")) or return
      reachable = @r["status"] == "connected"
      return if device.reachable == reachable
      device.update!(reachable:)
      changes.light_ids.concat(device.lights.pluck(:id))
    end

    def apply_power(changes)
      device = Device.find_by(id: @r.dig("owner", "rid")) or return
      level = @r.dig("power_state", "battery_level") or return
      device.update!(battery_percent: level) if device.battery_percent != level
    end
  end
end
