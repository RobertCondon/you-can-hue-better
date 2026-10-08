module Hue
  class Device < Record
    LIGHT = "light"
    DIMMER = "dimmer"
    DIAL = "dial"
    BRIDGE = "bridge"
    OTHER = "other"
    KINDS = [ LIGHT, DIMMER, DIAL, BRIDGE, OTHER ].freeze

    has_many :lights, dependent: :destroy
    has_many :controls, dependent: :destroy

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }
  end
end
