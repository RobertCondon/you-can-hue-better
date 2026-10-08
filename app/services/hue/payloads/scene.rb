module Hue
  module Payloads
    class Scene < Resource
      GROUP_FIELD = "group"
      DEFINITION_FIELDS = %w[actions palette speed auto_dynamic metadata].freeze

      def group_id = raw.dig(GROUP_FIELD, REFERENCE_ID_FIELD)
      def redefines_scene? = raw.keys.intersect?(DEFINITION_FIELDS)
    end
  end
end
