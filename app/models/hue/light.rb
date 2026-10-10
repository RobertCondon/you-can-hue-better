module Hue
  class Light < Record
    belongs_to :device
    has_many :group_lights, dependent: :destroy
    has_many :groups, through: :group_lights
    has_many :custom_scene_lights, class_name: "::CustomSceneLight", dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Light", foreign_key: :id, inverse_of: :hue_light, dependent: :destroy

    validates :name, presence: true
    validates :brightness, numericality: { in: Api::Limits::BRIGHTNESS }

    delegate :reachable?, to: :device

    def on? = on
    def off? = !on

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }
  end
end

# == Schema Information
#
# Table name: hue_lights
#
#  id         :string           not null, primary key
#  brightness :decimal(5, 2)    default(0.0), not null
#  color_x    :decimal(6, 4)
#  color_y    :decimal(6, 4)
#  id_v1      :string
#  mirek      :integer
#  name       :string           not null
#  on         :boolean          default(FALSE), not null
#  raw        :json             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  device_id  :string           not null
#
# Indexes
#
#  index_hue_lights_on_device_id  (device_id)
#
# Foreign Keys
#
#  device_id  (device_id => hue_devices.id)
#
