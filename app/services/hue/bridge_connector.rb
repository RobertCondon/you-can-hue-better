module Hue
  class BridgeConnector
    class FirstSyncFailed < Hue::Error; end

    attr_reader :bridge_address

    def initialize(bridge_address)
      @bridge_address = bridge_address.to_s.strip
    end

    def connect
      keys = LinkButtonPairing.new(bridge_address).request_keys
      BridgePairing.replace_current!(bridge: bridge_address, **keys.to_h)
      Hue.reset_client!
      synchronise_mirror
    end

    private

    def synchronise_mirror
      Sync.run
    rescue Hue::Error => error
      raise FirstSyncFailed, error.message
    end
  end
end
