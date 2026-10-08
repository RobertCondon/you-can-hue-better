require "test_helper"

class Hue::BridgeDiscoveryTest < ActiveSupport::TestCase
  test "lists the bridges the discovery service knows" do
    json_http = FakeJsonHttp.new(Hue::BridgeDiscovery::DISCOVERY_URL => [ { "id" => "abc", "internalipaddress" => "192.168.0.44" }, { "id" => "no-address" } ])
    bridges = Hue::BridgeDiscovery.new(json_http:).bridges
    assert_equal [ Hue::BridgeDiscovery::Bridge.new(id: "abc", address: "192.168.0.44") ], bridges
  end

  test "an unreachable service means no suggestions, not an error" do
    json_http = FakeJsonHttp.new { raise SocketError }
    assert_equal [], Hue::BridgeDiscovery.new(json_http:).bridges
  end
end
