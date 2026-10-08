class House
  module LightIcon
    LAMP = "lamp"
    ARCHETYPES_BY_ICON = {
      "candle" => %w[candle_bulb],
      "spot" => %w[spot_bulb ceiling_round ceiling_square recessed_ceiling recessed_floor single_spot double_spot wall_spot],
      "strip" => %w[hue_lightstrip hue_lightstrip_tv hue_lightstrip_pc string_light christmas_tree]
    }.freeze

    module_function

    def for_archetype(archetype)
      ARCHETYPES_BY_ICON.find { |_icon, archetypes| archetypes.include?(archetype.to_s) }&.first || LAMP
    end
  end
end
