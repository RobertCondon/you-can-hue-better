require "net/http"

# Thin wrapper over the Hue CLIP v2 API.
# Keeps one TLS connection open: the handshake costs ~100ms, a request ~15-70ms, and the bridge
# serialises requests anyway, so a single persistent connection behind a mutex is the fast path.
# The bridge uses a self-signed certificate, so verification is off; traffic never leaves the LAN.
module Hue
  class Client
    def initialize(config = Config.load)
      @config = config
      @mutex = Mutex.new
    end

    def lights          = get("light")
    def rooms           = get("room")
    def zones           = get("zone")
    def scenes          = get("scene")
    def devices         = get("device")
    def grouped_lights  = get("grouped_light")
    def smart_scenes    = get("smart_scene")
    def buttons         = get("button")
    def rotaries        = get("relative_rotary")
    def zigbee_connectivity = get("zigbee_connectivity")
    def device_power    = get("device_power")
    def light(id)       = get("light/#{id}").first

    # body examples:
    #   { on: { on: true } }
    #   { dimming: { brightness: 50 } }
    #   { color: { xy: { x: 0.3, y: 0.3 } } }
    def set_light(id, body)         = put("light/#{id}", body)
    def set_grouped_light(id, body) = put("grouped_light/#{id}", body)
    # action: "active" (the static look), "dynamic_palette" (play the palette), "static" (freeze a playing scene)
    def recall_scene(id, action: "active") = put("scene/#{id}", { recall: { action: } })

    # Names on the bridge (1-32 chars; the bridge validates). A light and the device that owns it
    # are named separately, so renaming a bulb means both.
    def rename_light(id, name)       = put("light/#{id}", { metadata: { name: } })
    def rename_device(id, name)      = put("device/#{id}", { metadata: { name: } })
    def rename_group(kind, id, name) = put("#{kind}/#{id}", { metadata: { name: } })

    private

    def get(path)
      request(Net::HTTP::Get.new(path_for(path)))["data"]
    end

    def put(path, body)
      req = Net::HTTP::Put.new(path_for(path))
      req["Content-Type"] = "application/json"
      req.body = body.to_json
      request(req)
    end

    def path_for(path) = "/clip/v2/resource/#{path}"

    def request(req)
      raise Error, "No bridge yet. Connect one on the setup page, or set HUE_BRIDGE and HUE_APP_KEY." unless @config.configured?

      req["hue-application-key"] = @config.app_key
      res = @mutex.synchronize do
        connection.request(req)
      rescue IOError, EOFError, Errno::EPIPE, Errno::ECONNRESET, OpenSSL::SSL::SSLError
        reset_connection
        connection.request(req) # one retry on a dropped keep-alive connection
      end

      json = JSON.parse(res.body)
      # A bulb with no power answers nothing; the bridge still stores the command and says so.
      # That is a warning for the person, not a failure of the request.
      unreachable, failures = json["errors"].to_a.partition { _1["description"].to_s.include?("communication issues") }
      raise Error, failures.map { _1["description"] }.join("; ") if failures.any?
      raise Error, "Bridge returned HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      json.merge("unreachable" => unreachable.any?)
    rescue Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      reset_connection
      raise Error, "Can't reach the bridge at #{@config.bridge} (#{e.class.name.demodulize})"
    end

    def connection
      @http ||= Net::HTTP.new(@config.bridge, 443).tap do |http|
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.open_timeout = 3
        http.read_timeout = 5
        http.keep_alive_timeout = 60
        http.start
      end
    end

    def reset_connection
      @http&.finish rescue nil
      @http = nil
    end
  end
end
