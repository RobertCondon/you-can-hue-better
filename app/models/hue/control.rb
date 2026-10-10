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

# == Schema Information
#
# Table name: hue_controls
#
#  id             :string           not null, primary key
#  control_number :integer
#  id_v1          :string
#  kind           :string           not null
#  last_event     :string
#  last_event_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  device_id      :string           not null
#
# Indexes
#
#  index_hue_controls_on_device_id                              (device_id)
#  index_hue_controls_on_device_id_and_kind_and_control_number  (device_id,kind,control_number) UNIQUE
#
# Foreign Keys
#
#  device_id  (device_id => hue_devices.id)
#
