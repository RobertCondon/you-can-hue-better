module HueExtensions
  class Scene < Record
    belongs_to :hue_scene, class_name: "Hue::Scene", foreign_key: :id, inverse_of: :extension

    validates :nickname, length: { maximum: MAX_NICKNAME_LENGTH }, allow_nil: true
  end
end
