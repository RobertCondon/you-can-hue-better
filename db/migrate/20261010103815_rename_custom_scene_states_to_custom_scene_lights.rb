class RenameCustomSceneStatesToCustomSceneLights < ActiveRecord::Migration[8.1]
  def up
    rename_table :custom_scene_states, :custom_scene_lights
  end

  def down
    rename_table :custom_scene_lights, :custom_scene_states
  end
end
