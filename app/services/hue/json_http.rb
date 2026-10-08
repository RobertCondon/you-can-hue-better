require "net/http"

module Hue
  class JsonHttp
    OPEN_TIMEOUT_SECONDS = 4
    READ_TIMEOUT_SECONDS = 6

    def get(url, self_signed: false)
      send_request(Net::HTTP::Get, url, payload: nil, self_signed:)
    end

    def post(url, payload, self_signed: false)
      send_request(Net::HTTP::Post, url, payload:, self_signed:)
    end

    private

    def send_request(request_class, url, payload:, self_signed:)
      uri = URI(url)
      request = request_class.new(uri.path)
      request[BridgeHttp::CONTENT_TYPE_HEADER] = BridgeHttp::JSON_CONTENT_TYPE
      request.body = payload.to_json if payload
      JSON.parse(http_for(uri, self_signed:).request(request).body)
    end

    def http_for(uri, self_signed:)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.is_a?(URI::HTTPS)
        http.verify_mode = self_signed ? BridgeHttp::SELF_SIGNED_CERTIFICATE_VERIFICATION : OpenSSL::SSL::VERIFY_PEER
        http.open_timeout = OPEN_TIMEOUT_SECONDS
        http.read_timeout = READ_TIMEOUT_SECONDS
      end
    end
  end
end
