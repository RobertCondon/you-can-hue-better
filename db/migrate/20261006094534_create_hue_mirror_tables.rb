# Mirror of bridge state. Written only by the sync/listener; Hue UUIDs are the primary keys.
class CreateHueMirrorTables < ActiveRecord::Migration[8.1]
  def change
    create_table :hue_devices, id: :string do |t|
      t.string  :name, null: false
      t.string  :product_name
      t.string  :kind, null: false, default: "other"      # light | dimmer | dial | bridge | other
      t.string  :id_v1
      t.boolean :reachable, null: false, default: true
      t.integer :battery_percent
      t.json    :raw, null: false, default: {}
      t.timestamps
    end

    create_table :hue_lights, id: :string do |t|
      t.references :device, type: :string, null: false, foreign_key: { to_table: :hue_devices }
      t.string  :name, null: false
      t.string  :id_v1
      t.boolean :on, null: false, default: false
      t.decimal :brightness, precision: 5, scale: 2, null: false, default: 0
      t.decimal :color_x, precision: 6, scale: 4
      t.decimal :color_y, precision: 6, scale: 4
      t.integer :mirek
      t.json    :raw, null: false, default: {}
      t.timestamps
    end

    create_table :hue_groups, id: :string do |t|
      t.string  :kind, null: false                       # room | zone | home
      t.string  :name, null: false
      t.string  :grouped_light_id, index: true
      t.string  :id_v1
      t.boolean :any_on, null: false, default: false
      t.decimal :brightness, precision: 5, scale: 2, null: false, default: 0
      t.json    :raw, null: false, default: {}
      t.timestamps
    end

    create_table :hue_group_lights do |t|
      t.references :group, type: :string, null: false, foreign_key: { to_table: :hue_groups }
      t.references :light, type: :string, null: false, foreign_key: { to_table: :hue_lights }
    end
    add_index :hue_group_lights, [ :group_id, :light_id ], unique: true

    create_table :hue_scenes, id: :string do |t|
      t.references :group, type: :string, null: false, foreign_key: { to_table: :hue_groups }
      t.string :name, null: false
      t.string :kind, null: false, default: "scene"      # scene | smart_scene
      t.string :id_v1
      t.json   :raw, null: false, default: {}
      t.timestamps
    end

    create_table :hue_controls, id: :string do |t|
      t.references :device, type: :string, null: false, foreign_key: { to_table: :hue_devices }
      t.string   :kind, null: false                      # button | rotary
      t.integer  :control_number                         # 1-4 as printed on the switch; nil for rotary
      t.string   :id_v1
      t.string   :last_event
      t.datetime :last_event_at
      t.timestamps
    end
    add_index :hue_controls, [ :device_id, :kind, :control_number ], unique: true

    create_table :hue_listener_states do |t|
      t.string   :last_event_id
      t.datetime :last_event_at
      t.datetime :connected_at
      t.datetime :full_sync_at
      t.timestamps
    end
  end
end
