module Hue
  DEFAULT_SETTLE_SECONDS = 0.3

  def self.client
    @client ||= Api::Client.new
  end

  def self.client=(replacement_client)
    @client = replacement_client
    @client_injected = !replacement_client.nil?
  end

  def self.reset_client!
    @client = nil unless @client_injected
  end

  def self.json_http
    @json_http ||= Api::JsonHttp.new
  end

  def self.json_http=(replacement_json_http)
    @json_http = replacement_json_http
  end

  def self.configured? = Config.load.configured?

  def self.wait_for_bridge = sleep(Rails.configuration.x.hue.settle_seconds || DEFAULT_SETTLE_SECONDS)
end
