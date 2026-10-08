require "net/http"

# First-run pairing: find the bridge, then ask it for an app key while its link button is pressed.
# The HTTP calls go through `transport` so tests can stand in for the bridge and the discovery service.
module Hue
  module Pairer
    DISCOVERY_URL = "https://discovery.meethue.com/"
    DEVICE_TYPE   = "you_can_hue_better##{(ENV["HOSTNAME"].presence || Socket.gethostname).to_s[0, 19]}"
    BUTTON_NOT_PRESSED = 101

    module_function

    # The bridges Philips' discovery service knows on this public IP, as [{ "id", "internalipaddress" }].
    # Nothing (not an error) when the service is unreachable: the person can type the address.
    def discover
      body = transport.call(:get, DISCOVERY_URL, nil)
      Array(JSON.parse(body)).select { _1["internalipaddress"].present? }
    rescue StandardError
      []
    end

    # Pair with the bridge at `bridge`. Returns { app_key:, client_key:, bridge_id: } or raises
    # Hue::Error with what to do next.
    def pair(bridge)
      raise Hue::Error, "Enter the bridge's address first." if bridge.blank?
      body = transport.call(:post, "https://#{bridge}/api", { devicetype: DEVICE_TYPE, generateclientkey: true })
      reply = Array(JSON.parse(body)).first || {}
      if (success = reply["success"])
        { app_key: success["username"], client_key: success["clientkey"], bridge_id: bridge_id_of(bridge) }
      elsif reply.dig("error", "type") == BUTTON_NOT_PRESSED
        raise Hue::Error, "Press the round button on the bridge, then try again within 30 seconds."
      else
        raise Hue::Error, "The bridge said: #{reply.dig("error", "description") || body.to_s[0, 120]}"
      end
    rescue JSON::ParserError
      raise Hue::Error, "That address answered, but not like a Hue bridge."
    rescue SocketError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise Hue::Error, "Can't reach a bridge at #{bridge} (#{e.class.name.demodulize}). Check the address and that this machine is on the same network."
    end

    def bridge_id_of(bridge)
      JSON.parse(transport.call(:get, "https://#{bridge}/api/0/config", nil))["bridgeid"]
    rescue StandardError
      nil
    end

    # (method, url, json_body_or_nil) -> response body string. The bridge's certificate is self-signed.
    def transport
      @transport ||= lambda do |method, url, body|
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.open_timeout = 4
        http.read_timeout = 6
        req = method == :post ? Net::HTTP::Post.new(uri.path) : Net::HTTP::Get.new(uri.path)
        req["Content-Type"] = "application/json"
        req.body = body.to_json if body
        http.request(req).body
      end
    end

    def transport=(callable)
      @transport = callable
    end
  end
end
