# Things drawn on a room's floor: walls (which block and bounce light) and furniture (decoration).
# x, y, w are percent of the floor's width; h is percent of its height. Circles use w as diameter.
class CreateFloorObjects < ActiveRecord::Migration[8.1]
  def change
    create_table :floor_objects do |t|
      t.references :group, type: :string, null: false, foreign_key: { to_table: :hue_groups, on_delete: :cascade }
      t.string  :kind, null: false                     # wall | box | circle
      t.decimal :x, precision: 5, scale: 2, null: false
      t.decimal :y, precision: 5, scale: 2, null: false
      t.decimal :w, precision: 5, scale: 2, null: false
      t.decimal :h, precision: 5, scale: 2, null: false
      t.string  :label
      t.timestamps
    end
  end
end
