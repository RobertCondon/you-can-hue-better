module Hue
  class Mirror
    class Sync
      class Step
        def initialize(snapshot)
          @snapshot = snapshot
        end

        private

        attr_reader :snapshot

        def upsert(model, id, attributes)
          record = model.find_or_initialize_by(id:)
          record.assign_attributes(attributes)
          record.save! if record.changed?
          id
        end
      end
    end
  end
end
