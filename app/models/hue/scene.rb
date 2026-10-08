module Hue
  class Scene < Record
    SCENE = "scene"
    SMART_SCENE = "smart_scene"
    KINDS = [ SCENE, SMART_SCENE ].freeze
    PLAYING = SceneRecall::PLAY_PALETTE
    INACTIVE = "inactive"

    belongs_to :group
    has_many :actions, class_name: "Hue::SceneAction", dependent: :delete_all
    has_many :binding_steps, class_name: "::ControlBindingStep", as: :scene, dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Scene", foreign_key: :id, inverse_of: :hue_scene, dependent: :destroy

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :recallable, -> { where(kind: SCENE) }

    def display_name = extension&.nickname.presence || name
    def playing? = active == PLAYING
    def active? = active != INACTIVE
    def dynamic? = palette_hexes.any?

    def assign_from_raw(raw_scene) = assign_attributes(Payloads::Scene.new(raw_scene).reported_attributes)

    def rebuild_actions! = SceneActionRebuild.new(self).run

    def palette_hexes = Payloads::Palette.new(palette).hexes

    def siblings
      return Scene.none unless image_id

      Scene.recallable.where(image_id:).where.not(id:).includes(group: :extension)
    end
  end
end
