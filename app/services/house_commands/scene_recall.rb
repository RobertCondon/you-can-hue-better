module HouseCommands
  class SceneRecall < Command
    ACTIVITY_KIND = "scene"
    ACTIVITY_ACTIONS = { Hue::Api::SceneRecall::STATIC_LOOK => "scene", Hue::Api::SceneRecall::PLAY_PALETTE => "play" }.freeze

    def initialize(scene, mode)
      @scene = scene
      @mode = mode
    end

    def light_ids = @light_ids ||= @scene.actions.pluck(:light_id)

    def unreachable_description = Toasts.a_light_in(@scene.group.name)

    private

    def activity
      target_name = I18n.t("house_commands.scene_recall.target", scene: @scene.name, room: @scene.group.name)
      { target_kind: ACTIVITY_KIND, target_id: @scene.id, target_name:, action: activity_action }
    end

    def send_to_bridge = Hue.client.scenes.recall(@scene.id, action: @mode)

    def catch_up_mirror = super.tap { |changes| changes.scene_changed(@scene.id) }

    def activity_action = ACTIVITY_ACTIONS.fetch(@mode)
  end
end
