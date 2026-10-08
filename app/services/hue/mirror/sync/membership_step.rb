module Hue
  class Mirror
    class Sync
      class MembershipStep < Step
        def call
          memberships = (room_memberships + zone_memberships + home_memberships).select { |_group_id, light_id| known_light_ids.include?(light_id) }.uniq
          GroupLight.delete_all
          GroupLight.insert_all(memberships.map { |group_id, light_id| { group_id:, light_id: } }) if memberships.any?
        end

        private

        def room_memberships
          snapshot.rooms.flat_map do |room|
            room.child_ids(of_type: Api::ResourceType::DEVICE).flat_map { |device_id| light_ids_by_device.fetch(device_id, []) }.map { |light_id| [ room.id, light_id ] }
          end
        end

        def zone_memberships
          snapshot.zones.flat_map { |zone| zone.child_ids(of_type: Api::ResourceType::LIGHT).map { |light_id| [ zone.id, light_id ] } }
        end

        def home_memberships
          Group.where(kind: Group::HOME).pluck(:id).product(known_light_ids.to_a)
        end

        def light_ids_by_device = @light_ids_by_device ||= snapshot.devices.to_h { |device| [ device.id, device.light_ids ] }

        def known_light_ids = @known_light_ids ||= Light.pluck(:id).to_set
      end
    end
  end
end
