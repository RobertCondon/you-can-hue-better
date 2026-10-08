module Hue
  module Payloads
    class Resource
      ID_FIELD = "id"
      TYPE_FIELD = "type"
      LEGACY_ID_FIELD = "id_v1"
      METADATA_FIELD = "metadata"
      NAME_FIELD = "name"
      OWNER_FIELD = "owner"
      REFERENCE_ID_FIELD = "rid"
      REFERENCE_TYPE_FIELD = "rtype"

      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def id = raw[ID_FIELD]
      def type = raw[TYPE_FIELD]
      def legacy_id = raw[LEGACY_ID_FIELD]
      def name = raw.dig(METADATA_FIELD, NAME_FIELD)
      def owner_id = raw.dig(OWNER_FIELD, REFERENCE_ID_FIELD)
      def owner_type = raw.dig(OWNER_FIELD, REFERENCE_TYPE_FIELD)

      private

      def referenced_ids(references, of_type:)
        references.to_a.select { |reference| reference[REFERENCE_TYPE_FIELD] == of_type }.map { |reference| reference[REFERENCE_ID_FIELD] }
      end
    end
  end
end
