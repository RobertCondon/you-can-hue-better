module HueExtensions
  # What the app knows about a bridge scene: nickname, favourite, hidden, order, and whether we made it.
  class Scene < Record
    belongs_to :hue_scene, class_name: "Hue::Scene", foreign_key: :id, inverse_of: :extension

    validates :nickname, length: { maximum: 40 }, allow_nil: true
  end
end
