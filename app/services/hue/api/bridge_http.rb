require "net/http"

module Hue
  module Api
    module BridgeHttp
      HTTPS_PORT = 443
      SELF_SIGNED_CERTIFICATE_VERIFICATION = OpenSSL::SSL::VERIFY_NONE
      APPLICATION_KEY_HEADER = "hue-application-key"
      CONTENT_TYPE_HEADER = "Content-Type"
      JSON_CONTENT_TYPE = "application/json"
      UNREACHABLE_ERRORS = [ SocketError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout ].freeze
      DROPPED_CONNECTION_ERRORS = [ IOError, EOFError, Errno::EPIPE, Errno::ECONNRESET, OpenSSL::SSL::SSLError ].freeze

      module_function

      def connection(host, open_timeout:, read_timeout:)
        Net::HTTP.new(host, HTTPS_PORT).tap do |http|
          http.use_ssl = true
          http.verify_mode = SELF_SIGNED_CERTIFICATE_VERIFICATION
          http.open_timeout = open_timeout
          http.read_timeout = read_timeout
        end
      end

      def unreachable_message(bridge_address, error)
        "Can't reach the bridge at #{bridge_address} (#{error.class.name.demodulize})"
      end
    end
  end
end
