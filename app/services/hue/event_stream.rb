require "net/http"

module Hue
  class EventStream
    PATH = "/eventstream/clip/v2"
    ACCEPT_HEADER = "Accept"
    EVENT_STREAM_CONTENT_TYPE = "text/event-stream"
    OPEN_TIMEOUT_SECONDS = 5
    READ_TIMEOUT_SECONDS = (ListenerState::LIVENESS_WINDOW - ListenerState::HEARTBEAT_EVERY).to_i

    def initialize(config = Config.load, read_timeout: READ_TIMEOUT_SECONDS)
      @config = config
      @read_timeout = read_timeout
    end

    def each_batch(on_keepalive: -> { })
      parser = Parser.new
      http.start do |connection|
        connection.request(stream_request) do |response|
          raise Hue::Error, "Event stream refused: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          response.read_body do |chunk|
            parser.feed(chunk) do |message|
              message.keepalive? ? on_keepalive.call : yield(JSON.parse(message.data))
            end
          end
        end
      end
    end

    private

    def http = BridgeHttp.connection(@config.bridge, open_timeout: OPEN_TIMEOUT_SECONDS, read_timeout: @read_timeout)

    def stream_request
      Net::HTTP::Get.new(PATH).tap do |request|
        request[BridgeHttp::APPLICATION_KEY_HEADER] = @config.app_key
        request[ACCEPT_HEADER] = EVENT_STREAM_CONTENT_TYPE
      end
    end
  end
end
