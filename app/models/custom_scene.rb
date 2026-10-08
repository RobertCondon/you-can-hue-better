# A scene the app owns: one target state per light. Optionally mirrored to the bridge as a real
# Hue scene (hue_scene_id) so recall is one atomic call.
class CustomScene < ApplicationRecord
  belongs_to :group, class_name: "Hue::Group", optional: true
  belongs_to :hue_scene, class_name: "Hue::Scene", optional: true
  has_many :states, class_name: "CustomSceneState", dependent: :destroy
  has_many :lights, through: :states
  has_many :binding_steps, as: :scene, dependent: :destroy

  validates :name, presence: true
  validates :transition_ms, numericality: { greater_than_or_equal_to: 0 }

  # Snapshot the current mirror state of some lights into a new scene.
  def self.capture(name:, lights:, group: nil)
    create!(name:, group:) do |scene|
      lights.each do |l|
        scene.states.build(light: l, on: l.on, brightness: l.brightness, color_x: l.color_x, color_y: l.color_y, mirek: l.mirek)
      end
    end
  end

  # True when every light lives in one room/zone, so the bridge could hold it as a single scene.
  def fits_one_group? = group.present? && (lights - group.lights).empty?
end
