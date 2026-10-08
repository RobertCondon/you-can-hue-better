module Hue
  module Api
    module Payloads
      class Button < Resource
        BUTTON_FIELD = "button"
        REPORT_FIELD = "button_report"
        EVENT_FIELD = "event"
        UPDATED_FIELD = "updated"
        CONTROL_ID_FIELD = "control_id"

        def control_number = raw.dig(METADATA_FIELD, CONTROL_ID_FIELD)
        def reported? = report.present?
        def gesture = report[EVENT_FIELD]
        def reported_at = report[UPDATED_FIELD]

        private

        def report = raw.dig(BUTTON_FIELD, REPORT_FIELD).to_h
      end
    end
  end
end
