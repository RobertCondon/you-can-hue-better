class DropUndoActions < ActiveRecord::Migration[8.1]
  def change
    drop_table :undo_actions do |table|
      table.string :description, null: false
      table.json :states, default: [], null: false
      table.timestamps
    end
  end
end
