module Hue
  module Api
    module Payloads
      class ZigbeeConnectivity < Resource
        STATUS_FIELD = "status"
        CONNECTED = "connected"

        def connected? = raw[STATUS_FIELD] == CONNECTED
      end
    end
  end
end
