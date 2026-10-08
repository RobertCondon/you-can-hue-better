require "test_helper"

class Hue::Pairing::BridgeDiscoveryTest < ActiveSupport::TestCase
  test "lists the bridges the discovery service knows" do
    json_http = FakeJsonHttp.new(Hue::Pairing::BridgeDiscovery::DISCOVERY_URL => [ { "id" => "abc", "internalipaddress" => "192.168.0.44" }, { "id" => "no-address" } ])
    bridges = Hue::Pairing::BridgeDiscovery.new(json_http:).bridges
    assert_equal [ Hue::Pairing::BridgeDiscovery::Bridge.new(id: "abc", address: "192.168.0.44") ], bridges
  end

  test "an unreachable service means no suggestions, not an error" do
    json_http = FakeJsonHttp.new { raise SocketError }
    assert_equal [], Hue::Pairing::BridgeDiscovery.new(json_http:).bridges
  end
end
