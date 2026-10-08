module Hue
  class Light < Record
    belongs_to :device
    has_many :group_lights, dependent: :destroy
    has_many :groups, through: :group_lights
    has_many :custom_scene_states, class_name: "::CustomSceneState", dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Light", foreign_key: :id, inverse_of: :hue_light, dependent: :destroy

    validates :name, presence: true
    validates :brightness, numericality: { in: 0..100 }

    delegate :reachable?, to: :device

    def on?  = on
    def off? = !on

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }

    # The plain-Ruby value object the views already render.
    def to_snapshot
      House::Light.new(id:, name:, on:, brightness: brightness.to_f, xy:, owner_id: device_id,
        gamut: raw.dig("color", "gamut")&.transform_values { _1.symbolize_keys }&.symbolize_keys,
        mirek:, mirek_valid: raw.dig("color_temperature", "mirek_valid"), nickname: extension&.nickname, reachable: device.reachable,
        archetype: raw.dig("metadata", "archetype") || device.raw.dig("product_data", "product_archetype"),
        hidden: extension&.hidden, on_floor: extension.nil? || extension.on_floor, icon_override: extension&.icon)
    end
  end
end
