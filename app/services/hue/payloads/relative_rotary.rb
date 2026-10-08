module Hue
  module Payloads
    class RelativeRotary < Resource
      ROTARY_FIELD = "relative_rotary"
      REPORT_FIELD = "rotary_report"
      ACTION_FIELD = "action"
      UPDATED_FIELD = "updated"
      ROTATION_FIELD = "rotation"
      DIRECTION_FIELD = "direction"
      STEPS_FIELD = "steps"
      DURATION_FIELD = "duration"
      COUNTER_CLOCKWISE = "counter_clock_wise"

      def reported? = report.present?
      def action = report[ACTION_FIELD]
      def reported_at = report[UPDATED_FIELD]
      def direction = rotation[DIRECTION_FIELD]
      def steps = rotation[STEPS_FIELD]
      def duration = rotation[DURATION_FIELD]
      def gesture = direction == COUNTER_CLOCKWISE ? ControlBinding::ROTATE_COUNTER_CLOCKWISE : ControlBinding::ROTATE_CLOCKWISE

      private

      def report = raw.dig(ROTARY_FIELD, REPORT_FIELD).to_h
      def rotation = report[ROTATION_FIELD].to_h
    end
  end
end
