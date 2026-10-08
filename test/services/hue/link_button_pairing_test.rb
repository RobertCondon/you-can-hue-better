require "test_helper"

class Hue::LinkButtonPairingTest < ActiveSupport::TestCase
  BRIDGE_ADDRESS = "192.168.0.44"
  PAIRING_URL = "https://#{BRIDGE_ADDRESS}/api"
  CONFIG_URL = "https://#{BRIDGE_ADDRESS}/api/0/config"

  def pairing(json_http, address: BRIDGE_ADDRESS) = Hue::LinkButtonPairing.new(address, json_http:)

  test "after the button, returns the keys and the bridge id" do
    json_http = FakeJsonHttp.new(PAIRING_URL => [ { "success" => { "username" => "KEY", "clientkey" => "CK" } } ], CONFIG_URL => { "bridgeid" => "001788FFFE" })
    keys = pairing(json_http).request_keys
    assert_equal Hue::LinkButtonPairing::Keys.new(app_key: "KEY", client_key: "CK", bridge_id: "001788FFFE"), keys
    assert_equal [ :post, PAIRING_URL, { devicetype: Hue::LinkButtonPairing.device_type, generateclientkey: true } ], json_http.requests.first
  end

  test "before the button, says what to do" do
    json_http = FakeJsonHttp.new(PAIRING_URL => [ { "error" => { "type" => 101, "description" => "link button not pressed" } } ])
    assert_match(/Press the round button/, assert_raises(Hue::Error) { pairing(json_http).request_keys }.message)
  end

  test "a wrong or missing address explains itself" do
    unreachable = FakeJsonHttp.new { raise Errno::EHOSTUNREACH }
    assert_match(/Can't reach the bridge at 10.0.0.9/, assert_raises(Hue::Error) { pairing(unreachable, address: "10.0.0.9").request_keys }.message)

    not_a_bridge = FakeJsonHttp.new { raise JSON::ParserError }
    assert_match(/not like a Hue bridge/, assert_raises(Hue::Error) { pairing(not_a_bridge, address: "10.0.0.9").request_keys }.message)

    assert_match(/address first/, assert_raises(Hue::Error) { pairing(unreachable, address: " ").request_keys }.message)
  end
end
