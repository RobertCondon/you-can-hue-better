require "net/http"

module Hue
  class ClipResponse
    DATA_FIELD = "data"
    ERRORS_FIELD = "errors"
    DESCRIPTION_FIELD = "description"
    UNPOWERED_LIGHT_DESCRIPTION = "communication issues"
    FAILURE_SEPARATOR = "; "

    def initialize(http_response)
      @http_response = http_response
      @body = JSON.parse(http_response.body)
      raise_on_failure
    end

    def data = @body[DATA_FIELD]

    def command_result = CommandResult.new(unreachable_lights: unpowered_light_errors.any?)

    private

    def raise_on_failure
      raise Hue::Error, failures.map { |failure| failure[DESCRIPTION_FIELD] }.join(FAILURE_SEPARATOR) if failures.any?
      raise Hue::Error, "Bridge returned HTTP #{@http_response.code}" unless @http_response.is_a?(Net::HTTPSuccess)
    end

    def errors = @body[ERRORS_FIELD].to_a

    def unpowered_light_errors = errors.select { |error| unpowered_light?(error) }

    def failures = errors.reject { |error| unpowered_light?(error) }

    def unpowered_light?(error) = error[DESCRIPTION_FIELD].to_s.include?(UNPOWERED_LIGHT_DESCRIPTION)
  end
end
