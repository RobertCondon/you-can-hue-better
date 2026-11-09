class CreateLocalButtons < ActiveRecord::Migration[8.1]
  def up
    create_table :local_buttons do |t|
      t.string :client, null: false
      t.string :key, null: false
      t.string :name
      t.datetime :last_pressed_at
      t.integer :presses_count, null: false, default: 0
      t.timestamps
    end
    add_index :local_buttons, %i[client key], unique: true

    create_table :button_rules do |t|
      t.references :local_button, null: false, foreign_key: true
      t.string :gesture, null: false
      t.integer :position, null: false
      t.string :if_group_id
      t.string :if_state
      t.string :action, null: false
      t.string :target_group_id, null: false
      t.string :scene_id
      t.timestamps
    end
    add_index :button_rules, %i[local_button_id gesture position]
  end

  def down
    drop_table :button_rules
    drop_table :local_buttons
  end
end
