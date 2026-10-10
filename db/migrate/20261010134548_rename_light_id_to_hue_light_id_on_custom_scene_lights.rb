class RenameLightIdToHueLightIdOnCustomSceneLights < ActiveRecord::Migration[8.1]
  def up
    rename_column :custom_scene_lights, :light_id, :hue_light_id
  end

  def down
    rename_column :custom_scene_lights, :hue_light_id, :light_id
  end
end
