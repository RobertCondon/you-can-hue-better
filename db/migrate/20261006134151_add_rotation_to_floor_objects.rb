class AddRotationToFloorObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :floor_objects, :rotation, :integer, null: false, default: 0   # degrees, clockwise
  end
end
