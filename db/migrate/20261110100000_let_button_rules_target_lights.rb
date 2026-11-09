class LetButtonRulesTargetLights < ActiveRecord::Migration[8.1]
  def up
    rename_column :button_rules, :if_group_id, :if_subject_id
    add_column :button_rules, :if_subject_type, :string
    rename_column :button_rules, :target_group_id, :target_id
    add_column :button_rules, :target_type, :string
    add_column :button_rules, :brightness, :integer

    execute "UPDATE button_rules SET target_type = 'Hue::Group'"
    execute "UPDATE button_rules SET if_subject_type = 'Hue::Group' WHERE if_subject_id IS NOT NULL"
    change_column_null :button_rules, :target_type, false
  end

  def down
    execute "DELETE FROM button_rules WHERE target_type = 'Hue::Light' OR if_subject_type = 'Hue::Light' OR action = 'set_brightness'"
    remove_column :button_rules, :brightness
    remove_column :button_rules, :target_type
    rename_column :button_rules, :target_id, :target_group_id
    remove_column :button_rules, :if_subject_type
    rename_column :button_rules, :if_subject_id, :if_group_id
  end
end
