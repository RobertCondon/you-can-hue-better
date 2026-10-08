# App-owned facts about a Hue room or zone, one row per mirror row and sharing its id.
# The mirror (hue_groups) is rewritten by sync; this table never is.
class CreateHueExtensionsGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :hue_extensions_groups, id: :string do |t|
      t.integer :position
      t.timestamps
    end
    add_foreign_key :hue_extensions_groups, :hue_groups, column: :id, on_delete: :cascade
  end
end
