module Hue
  class Group < Record
    ROOM = "room"
    ZONE = "zone"
    HOME = "home"
    KINDS = [ ROOM, ZONE, HOME ].freeze

    has_many :group_lights, dependent: :destroy
    has_many :lights, through: :group_lights
    has_many :scenes, dependent: :destroy
    has_many :custom_scenes, class_name: "::CustomScene", dependent: :nullify
    has_one :extension, class_name: "::HueExtensions::Group", foreign_key: :id, inverse_of: :hue_group, dependent: :destroy
    has_many :placements, class_name: "::LightPlacement", dependent: :delete_all
    has_many :floor_objects, class_name: "::FloorObject", dependent: :delete_all
    has_many :floor_nets, class_name: "::FloorNet", dependent: :delete_all

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :rooms, -> { where(kind: ROOM) }
    scope :zones, -> { where(kind: ZONE) }

    def display_name = extension&.nickname.presence || name
  end
end
