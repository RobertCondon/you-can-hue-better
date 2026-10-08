# The bridge the app paired with from the setup page. One row: the latest pairing wins.
# Environment variables still take precedence (see Hue::Config), so a deployment can pin a key.
class BridgePairing < ApplicationRecord
  validates :bridge, :app_key, presence: true

  def self.current = order(paired_at: :desc).first

  def self.record!(bridge:, app_key:, client_key: nil, bridge_id: nil)
    transaction do
      delete_all
      create!(bridge:, app_key:, client_key:, bridge_id:, paired_at: Time.current)
    end
  end
end
