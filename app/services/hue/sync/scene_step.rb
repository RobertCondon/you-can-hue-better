module Hue
  class Sync
    class SceneStep < Step
      def run
        scene_ids = snapshot.scenes.filter_map { |scene| upsert_scene(scene, kind: Scene::SCENE) }
        smart_scene_ids = snapshot.smart_scenes.filter_map { |scene| upsert_scene(scene, kind: Scene::SMART_SCENE) }
        scene_ids + smart_scene_ids
      end

      private

      def upsert_scene(payload, kind:)
        return unless known_group_ids.include?(payload.group_id)

        scene = Scene.find_or_initialize_by(id: payload.id)
        scene.assign_attributes(group_id: payload.group_id, name: payload.name, kind:, id_v1: payload.legacy_id)
        scene.assign_from_raw(payload.raw)
        scene.save! if scene.changed?
        scene.rebuild_actions! if kind == Scene::SCENE
        scene.id
      end

      def known_group_ids = @known_group_ids ||= Group.pluck(:id).to_set
    end
  end
end
