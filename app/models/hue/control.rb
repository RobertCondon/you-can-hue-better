module Hue
  class Control < Record
    BUTTON = "button"
    ROTARY = "rotary"
    KINDS = [ BUTTON, ROTARY ].freeze

    belongs_to :device
    has_many :bindings, class_name: "::ControlBinding", dependent: :destroy
    has_many :control_events, class_name: "::ControlEvent", dependent: :destroy

    validates :kind, inclusion: { in: KINDS }
    validates :control_number, presence: true, if: :button?

    scope :buttons, -> { where(kind: BUTTON) }
    scope :rotaries, -> { where(kind: ROTARY) }

    def button? = kind == BUTTON
    def rotary? = kind == ROTARY

    def label
      button? ? I18n.t("hue.control.button_label", device: device.name, number: control_number) : I18n.t("hue.control.ring_label", device: device.name)
    end
  end
end
