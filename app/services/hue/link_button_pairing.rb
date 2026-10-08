module Hue
  class LinkButtonPairing
    APP_NAME = "you_can_hue_better"
    HOSTNAME_VARIABLE = "HOSTNAME"
    MAX_HOSTNAME_LENGTH = 19
    PAIRING_PATH = "/api"
    PUBLIC_CONFIG_PATH = "/api/0/config"
    SUCCESS_FIELD = "success"
    ERROR_FIELD = "error"
    ERROR_TYPE_FIELD = "type"
    ERROR_DESCRIPTION_FIELD = "description"
    APP_KEY_FIELD = "username"
    CLIENT_KEY_FIELD = "clientkey"
    BRIDGE_ID_FIELD = "bridgeid"
    LINK_BUTTON_NOT_PRESSED = 101
    MAX_UNEXPECTED_REPLY_LENGTH = 120
    MISSING_ADDRESS_MESSAGE = "Enter the bridge's address first."
    PRESS_BUTTON_MESSAGE = "Press the round button on the bridge, then try again within 30 seconds."
    NOT_A_BRIDGE_MESSAGE = "That address answered, but not like a Hue bridge."
    CHECK_NETWORK_ADVICE = "Check the address and that this machine is on the same network."

    Keys = Data.define(:app_key, :client_key, :bridge_id)

    def self.device_type
      hostname = ENV[HOSTNAME_VARIABLE].presence || Socket.gethostname
      "#{APP_NAME}##{hostname.first(MAX_HOSTNAME_LENGTH)}"
    end

    def initialize(bridge_address, json_http: Hue.json_http)
      @bridge_address = bridge_address.to_s.strip
      @json_http = json_http
    end

    def request_keys
      raise Hue::Error, MISSING_ADDRESS_MESSAGE if @bridge_address.blank?

      keys_from(pairing_reply)
    rescue JSON::ParserError
      raise Hue::Error, NOT_A_BRIDGE_MESSAGE
    rescue *BridgeHttp::UNREACHABLE_ERRORS, OpenSSL::SSL::SSLError => error
      raise Hue::Error, "#{BridgeHttp.unreachable_message(@bridge_address, error)}. #{CHECK_NETWORK_ADVICE}"
    end

    private

    def pairing_reply
      replies = @json_http.post(bridge_url(PAIRING_PATH), { devicetype: self.class.device_type, generateclientkey: true }, self_signed: true)
      Array(replies).first.to_h
    end

    def keys_from(reply)
      granted = reply[SUCCESS_FIELD]
      return Keys.new(app_key: granted[APP_KEY_FIELD], client_key: granted[CLIENT_KEY_FIELD], bridge_id:) if granted

      error = reply[ERROR_FIELD].to_h
      raise Hue::Error, PRESS_BUTTON_MESSAGE if error[ERROR_TYPE_FIELD] == LINK_BUTTON_NOT_PRESSED
      raise Hue::Error, "The bridge said: #{error[ERROR_DESCRIPTION_FIELD] || reply.to_s.first(MAX_UNEXPECTED_REPLY_LENGTH)}"
    end

    def bridge_id
      @json_http.get(bridge_url(PUBLIC_CONFIG_PATH), self_signed: true)[BRIDGE_ID_FIELD]
    rescue StandardError
      nil
    end

    def bridge_url(path) = "https://#{@bridge_address}#{path}"
  end
end
