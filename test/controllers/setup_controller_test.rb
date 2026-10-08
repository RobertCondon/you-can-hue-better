require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  def unconfigure!
    ENV.delete("HUE_BRIDGE"); ENV.delete("HUE_APP_KEY")
    Hue::Pairer.transport = ->(method, url, body) { url.include?("discovery") ? [ { id: "abc", internalipaddress: "192.168.0.44" } ].to_json : "[]" }
  end

  test "config precedence: environment, then the pairing, then the file" do
    assert_equal [ :env, "bridge.test" ], [ Hue::Config.load.source, Hue::Config.load.bridge ]
    ENV.delete("HUE_BRIDGE"); ENV.delete("HUE_APP_KEY")
    assert_equal :none, Hue::Config.load.source
    refute Hue.configured?
    BridgePairing.record!(bridge: "192.168.0.44", app_key: "K")
    assert_equal [ :paired, "192.168.0.44", "K" ], Hue::Config.load.then { [ _1.source, _1.bridge, _1.app_key ] }
    assert Hue.configured?
  end

  test "without a bridge every page is the setup page, which offers the bridge found on the network" do
    unconfigure!
    get root_path
    assert_redirected_to setup_path
    get floor_path
    assert_redirected_to setup_path
    get setup_path
    assert_response :success
    assert_select "input#setup_bridge[value='192.168.0.44']"
    assert_select "button", /pressed the button/
    assert_select ".setup__hint", /Found on your network/
  end

  test "pressing the button pairs, stores the key, syncs the mirror and goes to the lights" do
    unconfigure!
    Hue::Pairer.transport = ->(method, url, body) do
      case url
      when /discovery/ then "[]"
      when %r{/api/0/config} then { bridgeid: "BRIDGE1" }.to_json
      else [ { success: { username: "NEWKEY", clientkey: "CK" } } ].to_json
      end
    end
    post setup_path, params: { bridge: " 192.168.0.44 " }
    assert_redirected_to root_path
    pairing = BridgePairing.current
    assert_equal [ "192.168.0.44", "NEWKEY", "CK", "BRIDGE1" ], [ pairing.bridge, pairing.app_key, pairing.client_key, pairing.bridge_id ]
    assert Hue.configured?
    follow_redirect!
    assert_response :success
    assert_select ".flash", /Connected to the bridge at 192.168.0.44/
  end

  test "trying before the button sends you back with the instruction" do
    unconfigure!
    Hue::Pairer.transport = ->(method, url, body) { url.include?("discovery") ? "[]" : [ { error: { type: 101, description: "link button not pressed" } } ].to_json }
    post setup_path, params: { bridge: "192.168.0.44" }
    assert_redirected_to setup_path(bridge: "192.168.0.44")
    assert_match(/Press the round button/, flash[:alert])
    refute BridgePairing.exists?
  end

  test "when configured, the setup page says where the key came from and still allows pairing again" do
    get setup_path
    assert_response :success
    assert_select ".setup__current", /bridge.test/
    assert_select ".setup__current", /from the environment/
  end
end
