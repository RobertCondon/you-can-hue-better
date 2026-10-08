module HouseCommands
  class SceneRecall < Command
    ACTIVITY_KIND = "scene"
    ACTIVITY_ACTIONS = { Hue::Api::SceneRecall::STATIC_LOOK => "scene", Hue::Api::SceneRecall::PLAY_PALETTE => "play" }.freeze

    def initialize(scene, mode)
      @scene = scene
      @mode = mode
    end

    private

    def activity
      target_name = I18n.t("house_commands.scene_recall.target", scene: @scene.name, room: @scene.group.name)
      { target_kind: ACTIVITY_KIND, target_id: @scene.id, target_name:, action: activity_action }
    end

    def send_to_bridge = Hue.client.scenes.recall(@scene.id, action: @mode)

    def activity_action = ACTIVITY_ACTIONS.fetch(@mode)
  end
end
