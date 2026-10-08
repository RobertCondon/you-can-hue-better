module Hue
  class Mirror
    class SceneActionRebuild
      def self.call(scene) = new(scene).call

      def initialize(scene)
        @scene = scene
      end

      def call
        rows = known_light_actions.map { |action| action.row_attributes.merge(scene_id: @scene.id) }
        @scene.transaction do
          @scene.actions.delete_all
          SceneAction.insert_all(rows) if rows.any?
        end
        @scene.actions.reset
      end

      private

      def known_light_actions
        actions = Api::Payloads::Scene.new(@scene.raw).actions
        known_light_ids = Light.where(id: actions.map(&:light_id)).pluck(:id).to_set
        actions.select { |action| known_light_ids.include?(action.light_id) }
      end
    end
  end
end
