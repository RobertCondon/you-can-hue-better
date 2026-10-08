# Seeds bindings from the bridge's v1 rules (GET /api/<key>/rules) so the app can take over a
# remote with the behaviour it has today. Needs the mirror tables populated first (id_v1 lookups).
#
# v1 button codes are <button><event>: event 0 = press, 1 = hold, 2 = short release, 3 = long release.
# The rules act on press (x000) and hold (x001). We map press -> short_release (so a long press no
# longer also fires the short action) and hold -> repeat for dimming, long_press for everything else.
class LegacyRulesImport
  Result = Struct.new(:bindings, :skipped, keyword_init: true)

  BUTTON   = %r{\A/sensors/(\d+)/state/buttonevent\z}
  ROTATION = %r{\A/sensors/(\d+)/state/expectedrotation\z}
  STATUS   = %r{\A/sensors/(\d+)/state/status\z}   # a condition on a hidden status sensor
  SET      = %r{\A/sensors/(\d+)/state\z}          # an action writing one
  GROUP    = %r{\A/groups/(\d+)/action\z}
  LIGHT    = %r{\A/lights/(\d+)/state\z}

  def self.run(rules) = new(rules).run

  def initialize(rules)
    @rules = rules.map { |id, r| r.merge("id" => id) }
    @bindings = []
    @skipped = []
  end

  def run
    button_rules.group_by { |r| [ r[:sensor], r[:button], r[:hold] ] }.each do |(sensor, button, hold), rules|
      control = Hue::Control.find_by(id_v1: "/sensors/#{sensor}", kind: "button", control_number: button)
      next skip(rules, "no control for /sensors/#{sensor} button #{button}") unless control
      import_button(control, hold, rules)
    end
    rotary_rules.group_by { _1[:sensor] }.each do |sensor, rules|
      control = Hue::Control.find_by(id_v1: "/sensors/#{sensor}", kind: "rotary")
      next skip(rules, "no rotary control for /sensors/#{sensor}") unless control
      import_rotary(control, rules)
    end
    Result.new(bindings: @bindings, skipped: @skipped)
  end

  private

  def button_rules
    @rules.filter_map do |r|
      c = r["conditions"].find { _1["address"] =~ BUTTON && _1["operator"] == "eq" } or next
      code = c["value"].to_i
      r.merge(sensor: c["address"][BUTTON, 1], button: code / 1000, hold: code % 1000 == 1)
    end
  end

  def rotary_rules
    @rules.filter_map do |r|
      c = r["conditions"].find { _1["address"] =~ ROTATION } or next
      r.merge(sensor: c["address"][ROTATION, 1])
    end
  end

  def import_button(control, hold, rules)
    # A scene cycle: several rules on the same press, each gated on a status sensor value k and
    # setting it to k+1 while recalling a scene. Order by k.
    cycle = rules.filter_map do |r|
      gate  = r["conditions"].find { _1["address"] =~ STATUS && _1["operator"] == "eq" } or next
      scene = r["actions"].find { _1["body"].key?("scene") } or next
      [ gate["value"].to_i, scene ]
    end.sort_by(&:first)

    if cycle.any?
      group  = group_for(cycle.first.last["address"]) or return skip(rules, "unknown group")
      scenes = cycle.filter_map { |_, a| Hue::Scene.find_by(id_v1: "/scenes/#{a["body"]["scene"]}") }
      return skip(rules, "no scenes found for cycle") if scenes.empty?
      return save(control, hold ? "long_press" : "short_release", "cycle_scenes", group, { cycle_window_s: 10 }, rules, scenes:)
    end

    # A toggle: the press sets a status sensor, and other rules flip the group on/off from it.
    if (set = rules.flat_map { _1["actions"] }.find { _1["address"] =~ SET && _1["body"].key?("status") })
      flips = @rules.select { |r| r["conditions"].any? { _1["address"] == "#{set["address"]}/status" } }
      if (ga = flips.flat_map { _1["actions"] }.find { _1["address"] =~ GROUP })
        group = group_for(ga["address"]) or return skip(rules, "unknown group")
        return save(control, hold ? "long_press" : "short_release", "toggle_group", group, {}, rules)
      end
    end

    action = rules.flat_map { _1["actions"] }.find { _1["address"] =~ GROUP || _1["address"] =~ LIGHT } or return skip(rules, "no light/group action")
    body = action["body"]
    if action["address"] =~ LIGHT
      light = Hue::Light.find_by(id_v1: "/lights/#{$1}") or return skip(rules, "unknown light")
      settings = { on: body["on"], brightness: pct(body["bri"]), mirek: body["ct"], transition_ms: ms(body["transitiontime"]) }.compact
      return save(control, hold ? "long_press" : "short_release", "set_light", light, settings, rules)
    end

    group = group_for(action["address"]) or return skip(rules, "unknown group")
    if body.key?("bri_inc")
      save(control, hold ? "repeat" : "short_release", "brightness_delta", group, { delta: pct(body["bri_inc"]), transition_ms: ms(body["transitiontime"]) }.compact, rules)
    elsif body.key?("scene")
      scene = Hue::Scene.find_by(id_v1: "/scenes/#{body["scene"]}") or return skip(rules, "unknown scene")
      save(control, hold ? "long_press" : "short_release", "recall_scene", group, {}, rules, scenes: [ scene ])
    elsif body["on"] == false
      save(control, hold ? "long_press" : "short_release", "group_off", group, {}, rules)
    elsif body["on"] == true
      save(control, hold ? "long_press" : "short_release", "group_on", group, {}, rules)
    else
      skip(rules, "unrecognised body #{body}")
    end
  end

  # The rotary rules are speed bands: thresholds on expectedrotation (signed steps) -> bri_inc.
  # Clockwise bands are "gt N", anticlockwise bands are "lt -N"; both become min_steps = N + 1.
  # Rules gated on any_on == false describe what to do when turning a group that is off.
  def import_rotary(control, rules)
    group = rules.flat_map { _1["actions"] }.filter_map { group_for(_1["address"]) }.first or return skip(rules, "unknown group")
    bands = { rotate_cw: [], rotate_ccw: [] }
    on_if_off = {}
    rules.each do |r|
      gt = r["conditions"].find { _1["address"] =~ ROTATION && _1["operator"] == "gt" }&.dig("value")&.to_i
      lt = r["conditions"].find { _1["address"] =~ ROTATION && _1["operator"] == "lt" }&.dig("value")&.to_i
      body = r["actions"].find { _1["address"] =~ GROUP }["body"]
      if r["conditions"].any? { _1["address"].end_with?("any_on") && _1["value"] == "false" }
        fast = gt.to_i.positive?
        on_if_off[fast ? :fast : :slow] = { brightness: pct(body["bri"]), min_steps: fast ? gt + 1 : 0, transition_ms: ms(body["transitiontime"]) }.compact
      elsif body.key?("bri_inc")
        cw = body["bri_inc"].positive?
        bands[cw ? :rotate_cw : :rotate_ccw] << { min_steps: (cw ? gt : lt.abs) + 1, delta: pct(body["bri_inc"]).abs, transition_ms: ms(body["transitiontime"]) }.compact
      end
    end
    bands.each do |dir, list|
      next if list.empty?
      save(control, dir.to_s, "brightness_delta", group, { bands: list.sort_by { _1[:min_steps] }, on_if_off: }, rules)
    end
  end

  def save(control, gesture, action, target, settings, rules, scenes: nil)
    b = ControlBinding.find_or_initialize_by(control:, gesture:)
    b.assign_attributes(action:, target:, settings:, enabled: true)
    b.save!
    b.replace_steps!(scenes) if scenes
    @bindings << b
    b
  end

  def skip(rules, reason) = @skipped << { rules: rules.map { _1["id"] }, reason: }

  def group_for(address) = (m = address.match(GROUP)) && Hue::Group.find_by(id_v1: "/groups/#{m[1]}")
  def pct(bri) = bri && (bri.to_f / 254 * 100).round(1)
  def ms(transitiontime) = transitiontime && transitiontime * 100
end
