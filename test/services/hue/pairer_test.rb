require "test_helper"

class Hue::PairerTest < ActiveSupport::TestCase
  def fake(responses)
    calls = []
    Hue::Pairer.transport = ->(method, url, body) { calls << [ method, url, body ]; responses.fetch(url) }
    calls
  end

  test "discovery lists bridges, and nothing when the service is down" do
    fake("https://discovery.meethue.com/" => [ { id: "abc", internalipaddress: "192.168.0.44" } ].to_json)
    assert_equal [ "192.168.0.44" ], Hue::Pairer.discover.map { _1["internalipaddress"] }
    Hue::Pairer.transport = ->(*) { raise SocketError }
    assert_equal [], Hue::Pairer.discover
  end

  test "pairing after the button returns the keys and the bridge id" do
    calls = fake("https://192.168.0.44/api" => [ { success: { username: "KEY", clientkey: "CK" } } ].to_json,
                 "https://192.168.0.44/api/0/config" => { bridgeid: "001788FFFE" }.to_json)
    assert_equal({ app_key: "KEY", client_key: "CK", bridge_id: "001788FFFE" }, Hue::Pairer.pair("192.168.0.44"))
    assert_equal [ :post, "https://192.168.0.44/api", { devicetype: Hue::Pairer::DEVICE_TYPE, generateclientkey: true } ], calls.first
  end

  test "pairing before the button says what to do" do
    fake("https://192.168.0.44/api" => [ { error: { type: 101, description: "link button not pressed" } } ].to_json)
    e = assert_raises(Hue::Error) { Hue::Pairer.pair("192.168.0.44") }
    assert_match(/Press the round button/, e.message)
  end

  test "a wrong address explains itself" do
    Hue::Pairer.transport = ->(*) { raise Errno::EHOSTUNREACH }
    assert_match(/Can't reach a bridge at 10.0.0.9/, assert_raises(Hue::Error) { Hue::Pairer.pair("10.0.0.9") }.message)
    Hue::Pairer.transport = ->(*) { "<html>not a bridge</html>" }
    assert_match(/not like a Hue bridge/, assert_raises(Hue::Error) { Hue::Pairer.pair("10.0.0.9") }.message)
    assert_match(/address first/, assert_raises(Hue::Error) { Hue::Pairer.pair("") }.message)
  end
end
