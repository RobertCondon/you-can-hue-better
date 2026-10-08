require "test_helper"

class Hue::ConfigTest < ActiveSupport::TestCase
  test "the environment comes first" do
    config = Hue::Config.load
    assert_equal [ :environment, TEST_BRIDGE_ADDRESS, TEST_APP_KEY ], [ config.source, config.bridge, config.app_key ]
  end

  test "then a pairing made on the setup page" do
    unconfigure_bridge
    BridgePairing.replace_current!(bridge: "192.168.0.44", app_key: "PAIRED")
    config = Hue::Config.load
    assert_equal [ :paired, "192.168.0.44", "PAIRED" ], [ config.source, config.bridge, config.app_key ]
  end

  test "then the config file, and otherwise nothing" do
    unconfigure_bridge
    refute Hue.configured?
    assert_equal :none, Hue::Config.load.source

    Tempfile.create([ "hue", ".json" ]) do |file|
      file.write({ bridge: "10.0.0.2", username: "FILEKEY" }.to_json)
      file.flush
      Hue::Config.file_path = Pathname(file.path)
      config = Hue::Config.load
      assert_equal [ :file, "10.0.0.2", "FILEKEY" ], [ config.source, config.bridge, config.app_key ]
    end
  end
end
