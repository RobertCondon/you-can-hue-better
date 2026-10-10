module HueExtensions
  class Scene < Record
    belongs_to :hue_scene, class_name: "Hue::Scene", foreign_key: :id, inverse_of: :extension

    validates :nickname, length: { maximum: MAX_NICKNAME_LENGTH }, allow_nil: true
  end
end

# == Schema Information
#
# Table name: hue_extensions_scenes
#
#  id         :string           not null, primary key
#  favourite  :boolean          default(FALSE), not null
#  hidden     :boolean          default(FALSE), not null
#  made_here  :boolean          default(FALSE), not null
#  nickname   :string
#  notes      :text
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  id  (id => hue_scenes.id) ON DELETE => cascade
#
