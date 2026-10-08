module Hue
  class Mirror
    class RotaryApplier < Applier
      PAYLOAD_CLASS = Api::Payloads::RelativeRotary

      def apply
        return unless payload.reported?

        rotation = PressRecorder::Rotation.new(steps: payload.steps, direction: payload.direction, duration: payload.duration)
        PressRecorder.new(control_id: payload.id, gesture: payload.gesture, reported_at: payload.reported_at, event:, changes:, rotation:).record
      end
    end
  end
end
