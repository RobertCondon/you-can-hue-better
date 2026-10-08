module Hue
  class SceneActionRebuild
    def initialize(scene)
      @scene = scene
    end

    def run
      rows = known_light_actions.map { |action| action.row_attributes.merge(scene_id: @scene.id) }
      @scene.transaction do
        @scene.actions.delete_all
        SceneAction.insert_all(rows) if rows.any?
      end
      @scene.actions.reset
    end

    private

    def known_light_actions
      actions = Payloads::Scene.new(@scene.raw).actions
      known_light_ids = Light.where(id: actions.map(&:light_id)).pluck(:id).to_set
      actions.select { |action| known_light_ids.include?(action.light_id) }
    end
  end
end
