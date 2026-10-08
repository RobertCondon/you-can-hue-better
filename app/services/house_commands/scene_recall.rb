module HouseCommands
  class SceneRecall
    ACTIVITY_KIND = "scene"
    ACTIVITY_ACTIONS = { Hue::SceneRecall::STATIC_LOOK => "scene", Hue::SceneRecall::PLAY_PALETTE => "play" }.freeze

    def initialize(scene, mode)
      @scene = scene
      @mode = mode
    end

    def run
      room = @scene.group
      Undoable.run(
        description: I18n.t("house_commands.scene_recall.#{ACTIVITY_ACTIONS.fetch(@mode)}", scene: @scene.display_name, room: room.display_name),
        light_ids: @scene.actions.pluck(:light_id),
        activity: { target_kind: ACTIVITY_KIND, target_id: @scene.id, target_name: I18n.t("house_commands.scene_recall.target", scene: @scene.name, room: room.name), action: ACTIVITY_ACTIONS.fetch(@mode) }
      ) { Hue.client.scenes.recall(@scene.id, action: @mode) }
    end
  end
end
