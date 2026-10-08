# First run: connect the app to a Hue bridge. Reachable later too, to pair again or with another bridge.
class SetupController < ApplicationController
  skip_before_action :require_bridge

  def show
    @config  = Hue::Config.load
    @found   = Hue::Pairer.discover
    @bridge  = params[:bridge].presence || @config.bridge.presence || @found.first&.dig("internalipaddress")
  end

  def create
    bridge = params[:bridge].to_s.strip
    result = Hue::Pairer.pair(bridge)
    BridgePairing.record!(bridge:, app_key: result[:app_key], client_key: result[:client_key], bridge_id: result[:bridge_id])
    Hue.reset!
    begin
      Hue::Sync.run
    rescue Hue::Error => e
      return redirect_to root_path, alert: "Connected to the bridge at #{bridge}, but the first sync failed: #{e.message}"
    end
    redirect_to root_path, notice: "Connected to the bridge at #{bridge}."
  rescue Hue::Error => e
    redirect_to setup_path(bridge:), alert: e.message
  end
end
