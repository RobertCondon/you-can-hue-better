require "net/http"

module Hue
  module Api
    class PersistentConnection
      OPEN_TIMEOUT_SECONDS = 3
      READ_TIMEOUT_SECONDS = 5
      KEEP_ALIVE_SECONDS = 60
      NOT_CONFIGURED_MESSAGE = "No bridge yet. Connect one on the setup page, or set HUE_BRIDGE and HUE_APP_KEY."

      def initialize(config)
        @config = config
        @lock = Mutex.new
      end

      def get(path)
        perform(Net::HTTP::Get.new(path))
      end

      def put(path, payload)
        request = Net::HTTP::Put.new(path)
        request[BridgeHttp::CONTENT_TYPE_HEADER] = BridgeHttp::JSON_CONTENT_TYPE
        request.body = payload.to_json
        perform(request)
      end

      private

      def perform(request)
        raise Hue::Error, NOT_CONFIGURED_MESSAGE unless @config.configured?

        request[BridgeHttp::APPLICATION_KEY_HEADER] = @config.app_key
        @lock.synchronize { send_retrying_once_if_dropped(request) }
      rescue *BridgeHttp::UNREACHABLE_ERRORS => error
        close
        raise Hue::Error, BridgeHttp.unreachable_message(@config.bridge, error)
      end

      def send_retrying_once_if_dropped(request)
        open_http.request(request)
      rescue *BridgeHttp::DROPPED_CONNECTION_ERRORS
        close
        open_http.request(request)
      end

      def open_http
        @http ||= BridgeHttp.connection(@config.bridge, open_timeout: OPEN_TIMEOUT_SECONDS, read_timeout: READ_TIMEOUT_SECONDS).tap do |http|
          http.keep_alive_timeout = KEEP_ALIVE_SECONDS
          http.start
        end
      end

      def close
        @http&.finish
      rescue IOError
        nil
      ensure
        @http = nil
      end
    end
  end
end
