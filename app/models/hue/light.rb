module Hue
  class Light < Record
    belongs_to :device
    has_many :group_lights, dependent: :destroy
    has_many :groups, through: :group_lights
    has_many :custom_scene_states, class_name: "::CustomSceneState", dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Light", foreign_key: :id, inverse_of: :hue_light, dependent: :destroy

    validates :name, presence: true
    validates :brightness, numericality: { in: Api::Limits::BRIGHTNESS }

    delegate :reachable?, to: :device

    def on? = on
    def off? = !on

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }
  end
end
