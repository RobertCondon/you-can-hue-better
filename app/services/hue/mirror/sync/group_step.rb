module Hue
  class Mirror
    class Sync
      class GroupStep < Step
        HOME_NAME = "Home"

        def call
          room_ids = snapshot.rooms.map { |room| upsert_group(room, kind: Group::ROOM) }
          zone_ids = snapshot.zones.map { |zone| upsert_group(zone, kind: Group::ZONE) }
          room_ids + zone_ids + [ upsert_home ].compact
        end

        private

        def upsert_group(group, kind:)
          grouped_light = snapshot.grouped_light_of(group.id)
          upsert(Group, group.id, aggregate_attributes(grouped_light).merge(kind:, name: group.name, id_v1: group.legacy_id, raw: group.raw))
        end

        def upsert_home
          home = snapshot.bridge_home or return
          upsert(Group, home.owner_id, aggregate_attributes(home).merge(kind: Group::HOME, name: HOME_NAME, id_v1: home.legacy_id, raw: home.raw))
        end

        def aggregate_attributes(grouped_light)
          return { grouped_light_id: nil, any_on: false, brightness: Api::Payloads::Light::NO_BRIGHTNESS } unless grouped_light

          grouped_light.full_attributes.merge(grouped_light_id: grouped_light.id)
        end
      end
    end
  end
end
