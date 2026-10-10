module Html
  class SetupController < ApplicationController
    skip_before_action :require_bridge

    def show
      @config = Hue::Config.load
      @discovered_bridges = Hue::Pairing::BridgeDiscovery.new.bridges
      @bridge_address = params[:bridge].presence || @config.bridge.presence || @discovered_bridges.first&.address
    end

    def create
      connector = Hue::Pairing::BridgeConnector.new(params[:bridge])
      connector.connect
      redirect_to root_path, notice: t(".connected", address: connector.bridge_address)
    rescue Hue::Pairing::BridgeConnector::FirstSyncFailed => error
      redirect_to root_path, alert: t(".connected_without_sync", address: connector.bridge_address, reason: error.message)
    rescue Hue::Error => error
      redirect_to setup_path(bridge: connector.bridge_address), alert: error.message
    end
  end
end
