module Hue
  class Mirror
    class ButtonApplier < Applier
      PAYLOAD_CLASS = Api::Payloads::Button

      def apply
        return unless payload.reported?

        PressRecorder.new(control_id: payload.id, gesture: payload.gesture, reported_at: payload.reported_at, event:, changes:).record
      end
    end
  end
end
