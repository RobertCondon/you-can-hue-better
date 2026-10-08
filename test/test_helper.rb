ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/fake_hue_client"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    # The suite is "configured" through the environment; setup tests clear it to see the first run.
    setup { ENV["HUE_BRIDGE"] = "bridge.test"; ENV["HUE_APP_KEY"] = "test-key"; Hue::Config.file = Pathname("/nonexistent/hue.json"); Hue.client = FakeHueClient.new }
    teardown { Hue.client = nil; ENV.delete("HUE_BRIDGE"); ENV.delete("HUE_APP_KEY"); Hue::Config.file = nil; Hue::Pairer.transport = nil }

    def hue = Hue.client

    # Populate the mirror from the fake bridge and mark the listener live so House reads the mirror.
    def sync_mirror!
      Hue::Sync.run(hue)
      Hue::ListenerState.current.beat!
    end
  end
end
