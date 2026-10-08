module HueExtensions
  # What the app knows about a light that the bridge doesn't. Keyed by the Hue light id.
  class Light < Record
    belongs_to :hue_light, class_name: "Hue::Light", foreign_key: :id, inverse_of: :extension

    ICONS = %w[lamp candle spot strip].freeze

    validates :nickname, length: { maximum: 40 }, allow_nil: true
    validates :icon, inclusion: { in: ICONS }, allow_nil: true

    def self.set_nickname!(id, nickname)
      find_or_initialize_by(id:).update!(nickname: nickname.to_s.strip.presence)
    end

    # The /dev visibility list: hidden (everywhere outside /dev), on the floor, and which glyph.
    def self.set_visibility!(id, hidden: nil, on_floor: nil, icon: :keep)
      row = find_or_initialize_by(id:)
      row.hidden   = ActiveModel::Type::Boolean.new.cast(hidden)   unless hidden.nil?
      row.on_floor = ActiveModel::Type::Boolean.new.cast(on_floor) unless on_floor.nil?
      row.icon     = icon.to_s.presence unless icon == :keep
      row.save!
      row
    end
  end
end
