module Hue
  class BridgeDiscovery
    DISCOVERY_URL = "https://discovery.meethue.com/"
    ID_FIELD = "id"
    ADDRESS_FIELD = "internalipaddress"
    LOOKUP_FAILURES = [ *BridgeHttp::UNREACHABLE_ERRORS, JSON::ParserError, OpenSSL::SSL::SSLError ].freeze

    Bridge = Data.define(:id, :address)

    def initialize(json_http: Hue.json_http)
      @json_http = json_http
    end

    def bridges
      Array(@json_http.get(DISCOVERY_URL)).filter_map { |announcement| bridge_from(announcement) }
    rescue *LOOKUP_FAILURES
      []
    end

    private

    def bridge_from(announcement)
      address = announcement[ADDRESS_FIELD]
      Bridge.new(id: announcement[ID_FIELD], address:) if address.present?
    end
  end
end
