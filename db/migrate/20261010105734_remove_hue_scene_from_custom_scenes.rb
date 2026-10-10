class RemoveHueSceneFromCustomScenes < ActiveRecord::Migration[8.1]
  def up
    remove_reference :custom_scenes, :hue_scene, foreign_key: { to_table: :hue_scenes }, index: true
  end

  def down
    add_reference :custom_scenes, :hue_scene, type: :string, foreign_key: { to_table: :hue_scenes }, index: true
  end
end
