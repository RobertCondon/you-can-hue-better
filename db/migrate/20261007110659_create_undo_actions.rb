# What a multi-light action replaced, so it can be put back. Rows live for an hour.
class CreateUndoActions < ActiveRecord::Migration[8.1]
  def change
    create_table :undo_actions do |t|
      t.string :description, null: false
      t.json   :states, null: false, default: []
      t.timestamps
    end
  end
end
