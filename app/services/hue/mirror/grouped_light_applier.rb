module Hue
  class Mirror
    class GroupedLightApplier < Applier
      PAYLOAD_CLASS = Payloads::GroupedLight

      def apply
        group = Group.find_by(grouped_light_id: payload.id) or return
        group.assign_attributes(payload.reported_attributes)
        return unless group.changed?

        group.save!
        changes.group_changed(group.id)
      end
    end
  end
end
