module HueExtensions
  class Light < Record
    ICONS = %w[lamp candle spot strip].freeze
    BOOLEAN_SETTINGS = %w[hidden on_floor].freeze

    belongs_to :hue_light, class_name: "Hue::Light", foreign_key: :id, inverse_of: :extension

    validates :nickname, length: { maximum: MAX_NICKNAME_LENGTH }, allow_nil: true
    validates :icon, inclusion: { in: ICONS }, allow_nil: true

    def self.set_visibility!(id, settings)
      cast_settings = settings.to_h.to_h do |setting, value|
        BOOLEAN_SETTINGS.include?(setting.to_s) ? [ setting, cast_boolean(value) ] : [ setting, value.presence ]
      end
      find_or_initialize_by(id:).tap { |extension| extension.update!(cast_settings) }
    end
  end
end
