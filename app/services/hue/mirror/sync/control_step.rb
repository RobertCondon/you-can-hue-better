module Hue
  class Mirror
    class Sync
      class ControlStep < Step
        def call
          snapshot.buttons.map { |button| upsert_button(button) } + snapshot.relative_rotaries.map { |rotary| upsert_rotary(rotary) }
        end

        private

        def upsert_button(button)
          upsert(Control, button.id,
            device_id: button.owner_id, kind: Control::BUTTON, control_number: button.control_number, id_v1: button.legacy_id,
            last_event: button.gesture, last_event_at: button.reported_at)
        end

        def upsert_rotary(rotary)
          upsert(Control, rotary.id,
            device_id: rotary.owner_id, kind: Control::ROTARY, id_v1: rotary.legacy_id,
            last_event: rotary.action, last_event_at: rotary.reported_at)
        end
      end
    end
  end
end
