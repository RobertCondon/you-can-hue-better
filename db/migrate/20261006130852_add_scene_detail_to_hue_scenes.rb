# A scene's animated look (palette), its live status, and one row per light for its static look.
class AddSceneDetailToHueScenes < ActiveRecord::Migration[8.1]
  def change
    change_table :hue_scenes do |t|
      t.json     :palette, null: false, default: {}
      t.decimal  :speed, precision: 4, scale: 3
      t.boolean  :auto_dynamic, null: false, default: false
      t.string   :active, null: false, default: "inactive"   # inactive | static | dynamic_palette
      t.datetime :last_recalled_at
      t.datetime :last_actions_update
      t.string   :image_id                                     # stock-scene identity, shared across rooms
    end
    add_index :hue_scenes, :image_id

    create_table :hue_scene_actions do |t|
      t.references :scene, type: :string, null: false, foreign_key: { to_table: :hue_scenes, on_delete: :cascade }
      t.references :light, type: :string, null: false, foreign_key: { to_table: :hue_lights, on_delete: :cascade }
      t.boolean :on, null: false, default: true
      t.decimal :brightness, precision: 5, scale: 2
      t.decimal :color_x, precision: 6, scale: 4
      t.decimal :color_y, precision: 6, scale: 4
      t.integer :mirek
    end
    add_index :hue_scene_actions, [ :scene_id, :light_id ], unique: true

    create_table :hue_extensions_scenes, id: :string do |t|
      t.string  :nickname
      t.boolean :favourite, null: false, default: false
      t.boolean :hidden, null: false, default: false
      t.integer :position
      t.boolean :made_here, null: false, default: false
      t.text    :notes
      t.timestamps
    end
    add_foreign_key :hue_extensions_scenes, :hue_scenes, column: :id, on_delete: :cascade
  end
end
