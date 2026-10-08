# What the everyday views show. Hidden in /dev is hidden everywhere else.
class AddVisibilityToExtensions < ActiveRecord::Migration[8.1]
  def change
    add_column :hue_extensions_lights, :hidden,   :boolean, null: false, default: false
    add_column :hue_extensions_lights, :on_floor, :boolean, null: false, default: true
    add_column :hue_extensions_lights, :icon,     :string
    add_column :hue_extensions_groups, :hidden,   :boolean, null: false, default: false
  end
end
