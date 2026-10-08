ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/fake_bridge"
require_relative "support/fake_json_http"

module ActiveSupport
  class TestCase
    TEST_BRIDGE_ADDRESS = "bridge.test"
    TEST_APP_KEY = "test-key"
    MISSING_CONFIG_FILE = Pathname("/nonexistent/hue.json")

    parallelize(workers: :number_of_processors)

    setup do
      configure_bridge_through_environment
      Hue::Config.file_path = MISSING_CONFIG_FILE
      @fake_bridge = FakeBridge.new
      Hue.client = Hue::Api::Client.new(Hue::Config.load, connection: @fake_bridge)
    end

    teardown do
      Hue.client = nil
      Hue.json_http = nil
      Hue::Config.file_path = nil
      unconfigure_bridge
    end

    def hue = @fake_bridge

    def configure_bridge_through_environment
      ENV[Hue::Config::BRIDGE_VARIABLE] = TEST_BRIDGE_ADDRESS
      ENV[Hue::Config::APP_KEY_VARIABLE] = TEST_APP_KEY
    end

    def unconfigure_bridge
      ENV.delete(Hue::Config::BRIDGE_VARIABLE)
      ENV.delete(Hue::Config::APP_KEY_VARIABLE)
    end

    def sync_mirror!
      Hue::Mirror::Sync.call
      Hue::ListenerState.current.beat!
    end
  end
end
