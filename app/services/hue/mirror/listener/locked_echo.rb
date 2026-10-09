module Hue
  class Mirror
    class Listener
      module LockedEcho
        ID_FIELD = "id"

        module_function

        def match?(resource)
          case resource[Mirror::TYPE_FIELD]
          when Api::ResourceType::LIGHT then Locks.locked?(resource[ID_FIELD])
          when Api::ResourceType::GROUPED_LIGHT then any_locked?(room_light_ids(resource[ID_FIELD]))
          else false
          end
        end

        def room_light_ids(grouped_light_id) = GroupLight.joins(:group).where(group: { grouped_light_id: }).pluck(:light_id)

        def any_locked?(light_ids) = Locks.locked_among(light_ids).any?
      end
    end
  end
end
