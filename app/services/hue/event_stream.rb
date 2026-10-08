require "net/http"

module Hue
  # The bridge's server-sent events feed. `each` yields every batch (an array of events, each with
  # "id", "creationtime", "type" and "data") and calls `on_keepalive` for comment lines.
  class EventStream
    # Incremental SSE parser. Feed it chunks; it yields complete events as { id:, data:, comment: }.
    class Parser
      def initialize
        @buffer = +""
      end

      def feed(chunk)
        @buffer << chunk
        while (stop = @buffer.index("\n\n"))
          block = @buffer.slice!(0, stop + 2)
          yield parse(block)
        end
      end

      private

      def parse(block)
        event = { id: nil, data: +"", comment: nil }
        block.each_line(chomp: true) do |line|
          case line
          when /\A:(.*)/        then event[:comment] = $1.strip
          when /\Aid:\s?(.*)/   then event[:id] = $1
          when /\Adata:\s?(.*)/ then event[:data] << $1
          end
        end
        event
      end
    end

    # Shorter than the dashboard's liveness window (60s): a quiet stream reconnects and heartbeats
    # before the header can flip to "Not live", since the bridge sends no keepalives of its own.
    def initialize(config = Config.load, read_timeout: 45)
      @config = config
      @read_timeout = read_timeout
    end

    def each(on_keepalive: -> {})
      http = Net::HTTP.new(@config.bridge, 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.open_timeout = 5
      http.read_timeout = @read_timeout
      req = Net::HTTP::Get.new("/eventstream/clip/v2")
      req["hue-application-key"] = @config.app_key
      req["Accept"] = "text/event-stream"

      parser = Parser.new
      http.start do |conn|
        conn.request(req) do |res|
          raise Error, "Event stream refused: HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)
          res.read_body do |chunk|
            parser.feed(chunk) do |event|
              if event[:data].present?
                yield JSON.parse(event[:data])
              else
                on_keepalive.call
              end
            end
          end
        end
      end
    end
  end
end
