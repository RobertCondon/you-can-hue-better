module Hue
  class Scene < Record
    SCENE = "scene"
    SMART_SCENE = "smart_scene"
    KINDS = [ SCENE, SMART_SCENE ].freeze
    PLAYING = Api::SceneRecall::PLAY_PALETTE
    INACTIVE = "inactive"
    UNARRANGED_POSITION = Float::INFINITY

    belongs_to :group
    has_many :actions, class_name: "Hue::SceneAction", dependent: :delete_all
    has_many :binding_steps, class_name: "::ControlBindingStep", as: :scene, dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Scene", foreign_key: :id, inverse_of: :hue_scene, dependent: :destroy

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :recallable, -> { where(kind: SCENE) }
    scope :for_cards, -> { recallable.includes(:extension, group: :extension, actions: { light: [ :extension, :device ] }) }

    def self.arrange(scenes) = scenes.sort_by { |scene| [ scene.extension&.position || UNARRANGED_POSITION, scene.display_name ] }
    def self.by_room = for_cards.group_by(&:group_id).transform_values { |scenes| arrange(scenes) }

    def recallable? = kind == SCENE
    def display_name = extension&.nickname.presence || name
    def playing? = active == PLAYING
    def active? = active != INACTIVE
    def dynamic? = palette_hexes.any?

    def assign_from_raw(raw_scene) = assign_attributes(Api::Payloads::Scene.new(raw_scene).reported_attributes)

    def rebuild_actions! = Mirror::SceneActionRebuild.call(self)

    def palette_hexes = Api::Payloads::Palette.new(palette).hexes

    def siblings
      return Scene.none unless image_id

      Scene.recallable.where(image_id:).where.not(id:).includes(group: :extension)
    end
  end
end

# == Schema Information
#
# Table name: hue_scenes
#
#  id                  :string           not null, primary key
#  active              :string           default("inactive"), not null
#  auto_dynamic        :boolean          default(FALSE), not null
#  id_v1               :string
#  kind                :string           default("scene"), not null
#  last_actions_update :datetime
#  last_recalled_at    :datetime
#  name                :string           not null
#  palette             :json             not null
#  raw                 :json             not null
#  speed               :decimal(4, 3)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  group_id            :string           not null
#  image_id            :string
#
# Indexes
#
#  index_hue_scenes_on_group_id  (group_id)
#  index_hue_scenes_on_image_id  (image_id)
#
# Foreign Keys
#
#  group_id  (group_id => hue_groups.id)
#
