module Hue
  class Device < Record
    KINDS = %w[light dimmer dial bridge other].freeze

    has_many :lights, dependent: :destroy
    has_many :controls, dependent: :destroy

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :remotes, -> { where(kind: %w[dimmer dial]) }

    def remote? = kind.in?(%w[dimmer dial])

    def self.kind_for(product_name, has_light:)
      case product_name.to_s
      when /bridge/i   then "bridge"
      when /tap dial/i then "dial"
      when /dimmer/i   then "dimmer"
      else has_light ? "light" : "other"
      end
    end
  end
end
