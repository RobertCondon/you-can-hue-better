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

# == Schema Information
#
# Table name: hue_devices
#
#  id              :string           not null, primary key
#  battery_percent :integer
#  id_v1           :string
#  kind            :string           default("other"), not null
#  name            :string           not null
#  product_name    :string
#  raw             :json             not null
#  reachable       :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
