module Hue
  def self.client
    @client ||= Client.new
  end

  def self.client=(replacement_client)
    @client = replacement_client
    @client_injected = !replacement_client.nil?
  end

  def self.reset_client!
    @client = nil unless @client_injected
  end

  def self.json_http
    @json_http ||= JsonHttp.new
  end

  def self.json_http=(replacement_json_http)
    @json_http = replacement_json_http
  end

  def self.configured? = Config.load.configured?
end
