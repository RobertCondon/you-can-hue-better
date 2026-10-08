module Hue
  # A button or the rotary ring on a switch. Bindings hang off these.
  class Control < Record
    BUTTON = "button"
    ROTARY = "rotary"
    KINDS = [ BUTTON, ROTARY ].freeze

    belongs_to :device
    has_many :bindings, class_name: "::ControlBinding", dependent: :destroy
    has_many :control_events, class_name: "::ControlEvent", dependent: :destroy

    validates :kind, inclusion: { in: KINDS }
    validates :control_number, presence: true, if: :button?

    scope :buttons,  -> { where(kind: "button") }
    scope :rotaries, -> { where(kind: "rotary") }

    def button? = kind == "button"
    def rotary? = kind == "rotary"

    def label = button? ? "#{device.name} button #{control_number}" : "#{device.name} ring"

    def self.by_bridge_id(id) = find_by(id:)
  end
end
