module Hue
  class Mirror
    class SceneApplier < Applier
      PAYLOAD_CLASS = Payloads::Scene

      def apply
        return changes.full_sync_needed! unless event.update?

        scene = Scene.find_by(id: payload.id) or return changes.full_sync_needed!
        scene.assign_from_raw(scene.raw.deep_merge(payload.raw))
        return unless scene.changed?

        scene.save!
        scene.rebuild_actions! if payload.redefines_scene?
        changes.scene_changed(scene.id)
      end
    end
  end
end
