module Hue
  module Api
    module Payloads
      class Scene < Resource
        GROUP_FIELD = "group"
        IMAGE_FIELD = "image"
        PALETTE_FIELD = "palette"
        SPEED_FIELD = "speed"
        AUTO_DYNAMIC_FIELD = "auto_dynamic"
        STATUS_FIELD = "status"
        ACTIVE_FIELD = "active"
        LAST_RECALL_FIELD = "last_recall"
        LAST_ACTIONS_UPDATE_FIELD = "last_actions_update"
        ACTIONS_FIELD = "actions"
        DEFINITION_FIELDS = %w[actions palette speed auto_dynamic metadata].freeze

        def group_id = raw.dig(GROUP_FIELD, REFERENCE_ID_FIELD)
        def redefines_scene? = raw.keys.intersect?(DEFINITION_FIELDS)
        def actions = raw[ACTIONS_FIELD].to_a.map { |action| SceneAction.new(action) }

        def reported_attributes
          attributes = { raw: }
          attributes[:name] = name if name
          attributes[:image_id] = raw.dig(METADATA_FIELD, IMAGE_FIELD, REFERENCE_ID_FIELD) if raw[METADATA_FIELD]&.key?(IMAGE_FIELD)
          attributes[:palette] = raw[PALETTE_FIELD] if raw.key?(PALETTE_FIELD)
          attributes[:speed] = raw[SPEED_FIELD] if raw.key?(SPEED_FIELD)
          attributes[:auto_dynamic] = raw[AUTO_DYNAMIC_FIELD] if raw.key?(AUTO_DYNAMIC_FIELD)
          attributes[:active] = active_state if active_state
          attributes[:last_recalled_at] = last_recall if timestamp?(last_recall)
          attributes[:last_actions_update] = raw[LAST_ACTIONS_UPDATE_FIELD] if timestamp?(raw[LAST_ACTIONS_UPDATE_FIELD])
          attributes
        end

        private

        def active_state = raw.dig(STATUS_FIELD, ACTIVE_FIELD)
        def last_recall = raw.dig(STATUS_FIELD, LAST_RECALL_FIELD)
        def timestamp?(value) = value.is_a?(String)
      end
    end
  end
end
