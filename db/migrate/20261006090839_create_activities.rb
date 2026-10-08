class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :target_kind
      t.string :target_id
      t.string :target_name
      t.string :action
      t.json :payload
      t.string :result

      t.timestamps
    end
  end
end
