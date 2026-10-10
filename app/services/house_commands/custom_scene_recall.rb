module HouseCommands
  class CustomSceneRecall < Command
    ACTIVITY_KIND = "custom_scene"
    ACTIVITY_ACTION = "scene"

    def initialize(custom_scene)
      @custom_scene = custom_scene
    end

    def check_request!
      raise Hue::Error, I18n.t("house_commands.custom_scene_recall.no_lights") if light_ids.empty?
    end

    def light_ids = @light_ids ||= @custom_scene.lights.map(&:hue_light_id)

    private

    def activity
      { target_kind: ACTIVITY_KIND, target_id: @custom_scene.id.to_s, target_name: @custom_scene.name, action: ACTIVITY_ACTION }
    end

    def send_to_bridge
      Hue::Api::CommandResult.combine(@custom_scene.lights.map { |light|
        Hue.client.lights.update(light.hue_light_id, payload_for(light))
      })
    end

    def catch_up_mirror
      Hue.wait_for_bridge
      read_back_lights(light_ids)
    end

    def payload_for(light)
      dynamics = { duration: @custom_scene.transition_ms }
      return { on: { on: false }, dynamics: } unless light.on

      {
        on: { on: true },
        dynamics:,
        dimming: dimming(light),
        color: color(light),
        color_temperature: color_temperature(light)
      }.compact
    end

    def dimming(light)
      return if light.brightness.blank?

      { brightness: light.brightness.to_f }
    end

    def color(light)
      return if light.color_x.blank? || light.color_y.blank?

      { xy: { x: light.color_x.to_f, y: light.color_y.to_f } }
    end

    def color_temperature(light)
      return if light.mirek.blank?

      { mirek: light.mirek }
    end
  end
end
