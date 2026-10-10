module Hue
  class SceneAction < Record
    belongs_to :scene
    belongs_to :light

    def xy = color_x && { x: color_x.to_f, y: color_y.to_f }
    def color? = xy.present? || mirek.present?
    def white? = mirek.present? && xy.nil?

    def white_xy = mirek && Color.hex_to_xy(Color.mirek_to_hex(mirek))

    def hex
      return Color.xy_to_hex(xy[:x], xy[:y]) if xy
      return Color.mirek_to_hex(mirek) if mirek

      Color::WARM_WHITE_HEX
    end

    def hue_angle = Color.hue_angle(hex)
  end
end

# == Schema Information
#
# Table name: hue_scene_actions
#
#  id         :integer          not null, primary key
#  brightness :decimal(5, 2)
#  color_x    :decimal(6, 4)
#  color_y    :decimal(6, 4)
#  mirek      :integer
#  on         :boolean          default(TRUE), not null
#  light_id   :string           not null
#  scene_id   :string           not null
#
# Indexes
#
#  index_hue_scene_actions_on_light_id               (light_id)
#  index_hue_scene_actions_on_scene_id               (scene_id)
#  index_hue_scene_actions_on_scene_id_and_light_id  (scene_id,light_id) UNIQUE
#
# Foreign Keys
#
#  light_id  (light_id => hue_lights.id) ON DELETE => cascade
#  scene_id  (scene_id => hue_scenes.id) ON DELETE => cascade
#
