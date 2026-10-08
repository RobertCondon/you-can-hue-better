class AddHeartbeatToHueListenerStates < ActiveRecord::Migration[8.1]
  def change
    add_column :hue_listener_states, :heartbeat_at, :datetime
  end
end
