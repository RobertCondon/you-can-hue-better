module Hue
  class Mirror
    class Event < Data.define(:id, :occurred_at, :kind)
      UPDATE = "update"
      ID_FIELD = "id"
      CREATED_FIELD = "creationtime"
      KIND_FIELD = "type"
      DATA_FIELD = "data"

      def self.local = new(id: nil, occurred_at: nil, kind: UPDATE)

      def self.from_stream(stream_event)
        new(id: stream_event[ID_FIELD], occurred_at: stream_event[CREATED_FIELD], kind: stream_event[KIND_FIELD])
      end

      def self.resources_in(stream_event) = stream_event[DATA_FIELD]

      def update? = kind == UPDATE
      def from_bridge? = id.present?
    end
  end
end
