# Where a light sits on a room's floor, as percentages of the floor's width and height.
# Per room *and* light: the same bulb is in a room and in a zone, and the two floors differ.
class CreateLightPlacements < ActiveRecord::Migration[8.1]
  def change
    create_table :light_placements do |t|
      t.references :group, type: :string, null: false, foreign_key: { to_table: :hue_groups, on_delete: :cascade }
      t.references :light, type: :string, null: false, foreign_key: { to_table: :hue_lights, on_delete: :cascade }
      t.decimal :x, precision: 5, scale: 2, null: false
      t.decimal :y, precision: 5, scale: 2, null: false
      t.timestamps
    end
    add_index :light_placements, [ :group_id, :light_id ], unique: true

    add_column :hue_extensions_groups, :floor_aspect, :decimal, precision: 4, scale: 2, null: false, default: 1.0
  end
end
