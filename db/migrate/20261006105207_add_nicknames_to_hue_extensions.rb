# Dashboard-only names. The bridge never sees these.
class AddNicknamesToHueExtensions < ActiveRecord::Migration[8.1]
  def change
    add_column :hue_extensions_groups, :nickname, :string

    create_table :hue_extensions_lights, id: :string do |t|
      t.string :nickname
      t.timestamps
    end
    add_foreign_key :hue_extensions_lights, :hue_lights, column: :id, on_delete: :cascade
  end
end
