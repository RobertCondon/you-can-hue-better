module Hue
  module Api
    module Payloads
      class Device < Resource
        PRODUCT_DATA_FIELD = "product_data"
        PRODUCT_NAME_FIELD = "product_name"
        PRODUCT_ARCHETYPE_FIELD = "product_archetype"
        SERVICES_FIELD = "services"

        def product_name = raw.dig(PRODUCT_DATA_FIELD, PRODUCT_NAME_FIELD)
        def product_archetype = raw.dig(PRODUCT_DATA_FIELD, PRODUCT_ARCHETYPE_FIELD)
        def light_ids = referenced_ids(raw[SERVICES_FIELD], of_type: ResourceType::LIGHT)
        def has_light? = light_ids.any?
      end
    end
  end
end
