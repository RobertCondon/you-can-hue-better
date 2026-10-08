# App-owned tables: what remotes do, custom scenes, and the press history.
class CreateRemoteControlTables < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_scenes do |t|
      t.string :name, null: false
      t.references :group, type: :string, foreign_key: { to_table: :hue_groups }
      t.references :hue_scene, type: :string, foreign_key: { to_table: :hue_scenes }
      t.integer :transition_ms, null: false, default: 400
      t.timestamps
    end

    create_table :custom_scene_states do |t|
      t.references :custom_scene, null: false, foreign_key: true
      t.references :light, type: :string, null: false, foreign_key: { to_table: :hue_lights }
      t.boolean :on, null: false, default: true
      t.decimal :brightness, precision: 5, scale: 2
      t.decimal :color_x, precision: 6, scale: 4
      t.decimal :color_y, precision: 6, scale: 4
      t.integer :mirek
      t.timestamps
    end
    add_index :custom_scene_states, [ :custom_scene_id, :light_id ], unique: true

    create_table :control_bindings do |t|
      t.references :control, type: :string, null: false, foreign_key: { to_table: :hue_controls }
      t.string  :gesture, null: false
      t.string  :action, null: false
      t.string  :target_type
      t.string  :target_id
      t.json    :settings, null: false, default: {}
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :control_bindings, [ :control_id, :gesture ], unique: true
    add_index :control_bindings, [ :target_type, :target_id ]

    create_table :control_binding_steps do |t|
      t.references :control_binding, null: false, foreign_key: true
      t.integer :position, null: false
      t.string  :scene_type, null: false
      t.string  :scene_id, null: false
      t.timestamps
    end
    add_index :control_binding_steps, [ :control_binding_id, :position ], unique: true

    create_table :cycle_states do |t|
      t.references :control_binding, null: false, foreign_key: true, index: { unique: true }
      t.integer  :position, null: false, default: 0
      t.datetime :last_pressed_at
      t.timestamps
    end

    create_table :control_events do |t|
      t.references :control, type: :string, null: false, foreign_key: { to_table: :hue_controls }
      t.string   :gesture, null: false
      t.integer  :rotation_steps
      t.string   :rotation_direction
      t.integer  :duration_ms
      t.string   :bridge_event_id, null: false
      t.references :control_binding, foreign_key: true
      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
    end
    add_index :control_events, :occurred_at
    add_index :control_events, [ :bridge_event_id, :control_id ], unique: true

    add_column :activities, :source, :string, null: false, default: "dashboard"
    add_reference :activities, :control_event, foreign_key: true
  end
end
