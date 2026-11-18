class AddKindToLocalButtons < ActiveRecord::Migration[8.1]
  def change
    add_column :local_buttons, :kind, :string, null: false, default: "button"
  end
end
