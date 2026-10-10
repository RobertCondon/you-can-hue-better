class BridgePairing < ApplicationRecord
  validates :bridge, :app_key, presence: true

  def self.current = order(paired_at: :desc).first

  def self.replace_current!(bridge:, app_key:, client_key: nil, bridge_id: nil)
    transaction do
      delete_all
      create!(bridge:, app_key:, client_key:, bridge_id:, paired_at: Time.current)
    end
  end
end

# == Schema Information
#
# Table name: bridge_pairings
#
#  id         :integer          not null, primary key
#  app_key    :string           not null
#  bridge     :string           not null
#  client_key :string
#  paired_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  bridge_id  :string
#
