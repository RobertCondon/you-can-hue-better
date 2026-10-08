# The bridge the app paired with from the setup page, so a container keeps its key across restarts.
class CreateBridgePairings < ActiveRecord::Migration[8.1]
  def change
    create_table :bridge_pairings do |t|
      t.string :bridge, null: false
      t.string :app_key, null: false
      t.string :client_key
      t.string :bridge_id
      t.datetime :paired_at, null: false
      t.timestamps
    end
  end
end
