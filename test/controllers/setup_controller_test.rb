require "test_helper"

class SetupControllerTest < ActionDispatch::IntegrationTest
  BRIDGE_ADDRESS = "192.168.0.44"
  DISCOVERED = [ { "id" => "abc", "internalipaddress" => BRIDGE_ADDRESS } ].freeze
  GRANTED = [ { "success" => { "username" => "NEWKEY", "clientkey" => "CK" } } ].freeze
  BUTTON_NOT_PRESSED = [ { "error" => { "type" => 101, "description" => "link button not pressed" } } ].freeze

  def bridge_replies(pairing_reply)
    Hue.json_http = FakeJsonHttp.new do |url|
      case url
      when Hue::Pairing::BridgeDiscovery::DISCOVERY_URL then DISCOVERED
      when /config\z/ then { "bridgeid" => "BRIDGE1" }
      else pairing_reply
      end
    end
  end

  test "without a bridge every page is the setup page, which offers the bridge found on the network" do
    unconfigure_bridge
    bridge_replies(GRANTED)
    get root_path
    assert_redirected_to setup_path
    get floor_path
    assert_redirected_to setup_path
    get setup_path
    assert_response :success
    assert_select "input#setup_bridge[value='#{BRIDGE_ADDRESS}']"
    assert_select "button", /pressed the button/
    assert_select ".setup__hint", /Found on your network/
  end

  test "pressing the button pairs, stores the key, syncs the mirror and goes to the lights" do
    unconfigure_bridge
    bridge_replies(GRANTED)
    post setup_path, params: { bridge: " #{BRIDGE_ADDRESS} " }
    assert_redirected_to root_path
    pairing = BridgePairing.current
    assert_equal [ BRIDGE_ADDRESS, "NEWKEY", "CK", "BRIDGE1" ], [ pairing.bridge, pairing.app_key, pairing.client_key, pairing.bridge_id ]
    assert Hue.configured?
    follow_redirect!
    assert_response :success
    assert_select ".flash", /Connected to the bridge at #{BRIDGE_ADDRESS}/
  end

  test "trying before the button sends you back with the instruction" do
    unconfigure_bridge
    bridge_replies(BUTTON_NOT_PRESSED)
    post setup_path, params: { bridge: BRIDGE_ADDRESS }
    assert_redirected_to setup_path(bridge: BRIDGE_ADDRESS)
    assert_match(/Press the round button/, flash[:alert])
    refute BridgePairing.exists?
  end

  test "when configured, the setup page says where the key came from and still allows pairing again" do
    bridge_replies(GRANTED)
    get setup_path
    assert_response :success
    assert_select ".setup__current", /#{TEST_BRIDGE_ADDRESS}/
    assert_select ".setup__current", /from the environment/
  end
end
