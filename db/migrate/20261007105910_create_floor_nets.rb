# Closed loops drawn on the floor: one per room region (group_id set) and the house outline (group_id nil).
# Points are [x, y] pairs in percent of the floor's width and height. Labels, not physics, except that
# the outline blocks light like a wall.
class CreateFloorNets < ActiveRecord::Migration[8.1]
  def change
    create_table :floor_nets do |t|
      t.references :group, type: :string, foreign_key: { to_table: :hue_groups, on_delete: :cascade }
      t.json :points, null: false, default: []
      t.string :label
      t.timestamps
    end
  end
end
