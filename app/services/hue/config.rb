# Loads bridge connection details. Order of precedence:
#   1. ENV HUE_BRIDGE / HUE_APP_KEY
#   2. the pairing made on the setup page (bridge_pairings table)
#   3. config/hue.json  ({"bridge": "...", "username": "..."})
module Hue
  class Config
    attr_reader :bridge, :app_key, :source

    class << self
      attr_writer :file
      def file = @file || Rails.root.join("config/hue.json")
    end

    def self.load
      return new(bridge: ENV["HUE_BRIDGE"], app_key: ENV["HUE_APP_KEY"], source: :env) if ENV["HUE_BRIDGE"].present? && ENV["HUE_APP_KEY"].present?
      if (pairing = pairing_row)
        return new(bridge: pairing.bridge, app_key: pairing.app_key, source: :paired)
      end
      json = file.exist? ? JSON.parse(file.read) : {}
      new(bridge: ENV.fetch("HUE_BRIDGE") { json["bridge"] }, app_key: ENV.fetch("HUE_APP_KEY") { json["username"] }, source: json.any? ? :file : :none)
    end

    # The table may not exist yet (first boot, before migrations); treat that as "not paired".
    def self.pairing_row
      BridgePairing.current if BridgePairing.table_exists?
    rescue ActiveRecord::ActiveRecordError
      nil
    end

    def initialize(bridge:, app_key:, source: :none)
      @bridge = bridge
      @app_key = app_key
      @source = source
    end

    def configured?
      bridge.present? && app_key.present?
    end
  end
end
