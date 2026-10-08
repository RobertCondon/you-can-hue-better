require "test_helper"

class Hue::Api::ClipResponseTest < ActiveSupport::TestCase
  def http_response(body, success: true)
    response_class = success ? Net::HTTPOK : Net::HTTPInternalServerError
    response_class.new("1.1", success ? "200" : "500", "").tap do |response|
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, body.to_json)
    end
  end

  test "returns the data of a successful read" do
    assert_equal [ { "id" => "l1" } ], Hue::Api::ClipResponse.new(http_response({ data: [ { id: "l1" } ], errors: [] })).data
  end

  test "an unpowered bulb is a warning on the command, not a failure" do
    response = http_response({ data: [], errors: [ { description: "device (light) has communication issues, command (on) may not have effect" } ] })
    assert Hue::Api::ClipResponse.new(response).command_result.unreachable_lights?
  end

  test "any other bridge error is raised with its description" do
    response = http_response({ data: [], errors: [ { description: "invalid value" }, { description: "not allowed" } ] })
    assert_equal "invalid value; not allowed", assert_raises(Hue::Error) { Hue::Api::ClipResponse.new(response) }.message
  end

  test "a failed HTTP status is raised" do
    assert_match(/HTTP 500/, assert_raises(Hue::Error) { Hue::Api::ClipResponse.new(http_response({ errors: [] }, success: false)) }.message)
  end
end
