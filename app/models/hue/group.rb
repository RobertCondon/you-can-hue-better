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
    has_many :floor_placements, class_name: "::Floor::Placement", dependent: :delete_all
    has_many :floor_items, class_name: "::Floor::Item", dependent: :delete_all
    has_many :floor_nets, class_name: "::Floor::Net", dependent: :delete_all

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :rooms, -> { where(kind: ROOM) }
    scope :zones, -> { where(kind: ZONE) }

    def display_name = extension&.nickname.presence || name
  end
end

# == Schema Information
#
# Table name: hue_groups
#
#  id               :string           not null, primary key
#  any_on           :boolean          default(FALSE), not null
#  brightness       :decimal(5, 2)    default(0.0), not null
#  id_v1            :string
#  kind             :string           not null
#  name             :string           not null
#  raw              :json             not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  grouped_light_id :string
#
# Indexes
#
#  index_hue_groups_on_grouped_light_id  (grouped_light_id)
#
