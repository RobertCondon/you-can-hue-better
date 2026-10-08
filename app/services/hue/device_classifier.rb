module Hue
  module DeviceClassifier
    PRODUCT_PATTERNS = {
      Device::BRIDGE => /bridge/i,
      Device::DIAL => /tap dial/i,
      Device::DIMMER => /dimmer/i
    }.freeze

    module_function

    def kind_for(product_name, has_light:)
      matched_kind = PRODUCT_PATTERNS.find { |_kind, pattern| product_name.to_s.match?(pattern) }&.first
      matched_kind || (has_light ? Device::LIGHT : Device::OTHER)
    end
  end
end
