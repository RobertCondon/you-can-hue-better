module Hue
  class Mirror
    class PressRecorder
      Rotation = Data.define(:steps, :direction, :duration)
      NO_ROTATION = Rotation.new(steps: nil, direction: nil, duration: nil)

      def initialize(control_id:, gesture:, reported_at:, event:, changes:, rotation: NO_ROTATION)
        @control_id = control_id
        @gesture = gesture
        @reported_at = reported_at
        @event = event
        @changes = changes
        @rotation = rotation
      end

      def record
        control = Control.find_by(id: @control_id) or return @changes.full_sync_needed!
        control.update_columns(last_event: @gesture, last_event_at: @reported_at || Time.current)
        log_press(control) if @event.from_bridge?
      end

      private

      def log_press(control)
        control_event = ControlEvent.find_or_create_by!(control:, bridge_event_id: @event.id) do |new_event|
          new_event.gesture = @gesture
          new_event.rotation_steps = @rotation.steps
          new_event.rotation_direction = @rotation.direction
          new_event.duration_ms = @rotation.duration
          new_event.occurred_at = @event.occurred_at || @reported_at || Time.current
        end
        @changes.press_recorded(control_event) if control_event.previously_new_record?
      end
    end
  end
end
