module Hue
  class Config
    BRIDGE_VARIABLE = "HUE_BRIDGE"
    APP_KEY_VARIABLE = "HUE_APP_KEY"
    DEFAULT_FILE_PATH = "config/hue.json"
    FILE_BRIDGE_FIELD = "bridge"
    FILE_APP_KEY_FIELD = "username"

    attr_reader :bridge, :app_key, :source

    class << self
      attr_writer :file_path

      def file_path = @file_path || Rails.root.join(DEFAULT_FILE_PATH)

      def load
        from_environment || from_stored_pairing || from_file || unconfigured
      end

      private

      def from_environment
        bridge, app_key = ENV.values_at(BRIDGE_VARIABLE, APP_KEY_VARIABLE)
        new(bridge:, app_key:, source: :environment) if bridge.present? && app_key.present?
      end

      def from_stored_pairing
        pairing = stored_pairing_once_migrated
        new(bridge: pairing.bridge, app_key: pairing.app_key, source: :paired) if pairing
      end

      def from_file
        return unless file_path.exist?

        settings = JSON.parse(file_path.read)
        new(bridge: settings[FILE_BRIDGE_FIELD], app_key: settings[FILE_APP_KEY_FIELD], source: :file)
      end

      def unconfigured = new(bridge: nil, app_key: nil, source: :none)

      def stored_pairing_once_migrated
        BridgePairing.current if BridgePairing.table_exists?
      rescue ActiveRecord::ActiveRecordError
        nil
      end
    end

    def initialize(bridge:, app_key:, source:)
      @bridge = bridge
      @app_key = app_key
      @source = source
    end

    def configured? = bridge.present? && app_key.present?
  end
end
