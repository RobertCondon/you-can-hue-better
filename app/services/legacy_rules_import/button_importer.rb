class LegacyRulesImport
  class ButtonImporter
    SCENE_KEY = "scene"
    STATUS_KEY = "status"
    ON_KEY = "on"
    BRIGHTNESS_KEY = "bri"
    BRIGHTNESS_STEP_KEY = "bri_inc"
    TEMPERATURE_KEY = "ct"
    TRANSITION_KEY = "transitiontime"

    def initialize(control:, hold:, rules:, all_rules:, outcome:)
      @control = control
      @hold = hold
      @rules = rules
      @all_rules = all_rules
      @outcome = outcome
    end

    def import
      return import_scene_cycle if scene_cycle_steps.any?
      return import_toggle if toggle_action

      import_single_action
    end

    private

    def press_gesture = @hold ? ControlBinding::LONG_PRESS : ControlBinding::SHORT_RELEASE

    def dimming_gesture = @hold ? ControlBinding::REPEAT : ControlBinding::SHORT_RELEASE

    def save(action, target, gesture: press_gesture, settings: {}, scenes: nil)
      @outcome.save_binding(control: @control, gesture:, action:, target:, settings:, scenes:)
    end

    def skip(reason) = @outcome.skip(@rules, reason)

    def all_actions = @rules.flat_map(&:actions)

    def scene_cycle_steps
      @scene_cycle_steps ||= @rules.filter_map do |rule|
        gate = rule.status_gate or next
        scene_action = rule.actions.find { |action| action.body.key?(SCENE_KEY) } or next
        [ gate, scene_action ]
      end.sort_by(&:first).map(&:last)
    end

    def import_scene_cycle
      group = Addresses.group_for(scene_cycle_steps.first.address) or return skip("unknown group")
      scenes = scene_cycle_steps.filter_map { |action| Addresses.scene_for(action.body[SCENE_KEY]) }
      return skip("no scenes found for cycle") if scenes.empty?

      save(ControlBinding::CYCLE_SCENES, group, settings: { ControlBinding::CYCLE_WINDOW_SETTING => ControlBinding::DEFAULT_CYCLE_WINDOW_SECONDS }, scenes:)
    end

    def toggle_action
      @toggle_action ||= begin
        status_write = all_actions.find { |action| Addresses::STATUS_WRITE.match?(action.address) && action.body.key?(STATUS_KEY) }
        status_address = status_write && "#{status_write.address}#{Addresses::STATUS_SUFFIX}"
        status_rules = status_address ? @all_rules.select { |rule| rule.conditioned_on?(status_address) } : []
        status_rules.filter_map { |rule| rule.action_matching(Addresses::GROUP_ACTION) }.first
      end
    end

    def import_toggle
      group = Addresses.group_for(toggle_action.address) or return skip("unknown group")
      save(ControlBinding::TOGGLE_GROUP, group)
    end

    def import_single_action
      action = all_actions.find { |candidate| Addresses::GROUP_ACTION.match?(candidate.address) || Addresses::LIGHT_STATE.match?(candidate.address) }
      return skip("no light/group action") unless action
      return import_light_action(action) if Addresses::LIGHT_STATE.match?(action.address)

      import_group_action(action)
    end

    def import_light_action(action)
      light = Addresses.light_for(action.address) or return skip("unknown light")
      body = action.body
      settings = { on: body[ON_KEY], brightness: V1Units.percent(body[BRIGHTNESS_KEY]), mirek: body[TEMPERATURE_KEY], transition_ms: V1Units.milliseconds(body[TRANSITION_KEY]) }.compact
      save(ControlBinding::SET_LIGHT, light, settings:)
    end

    def import_group_action(action)
      group = Addresses.group_for(action.address) or return skip("unknown group")
      body = action.body
      if body.key?(BRIGHTNESS_STEP_KEY)
        settings = { delta: V1Units.percent(body[BRIGHTNESS_STEP_KEY]), transition_ms: V1Units.milliseconds(body[TRANSITION_KEY]) }.compact
        save(ControlBinding::BRIGHTNESS_DELTA, group, gesture: dimming_gesture, settings:)
      elsif body.key?(SCENE_KEY)
        scene = Addresses.scene_for(body[SCENE_KEY]) or return skip("unknown scene")
        save(ControlBinding::RECALL_SCENE, group, scenes: [ scene ])
      elsif body[ON_KEY] == false
        save(ControlBinding::GROUP_OFF, group)
      elsif body[ON_KEY] == true
        save(ControlBinding::GROUP_ON, group)
      else
        skip("unrecognised body #{body}")
      end
    end
  end
end
