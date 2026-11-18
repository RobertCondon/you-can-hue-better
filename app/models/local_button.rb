# A physical button on a board on the home network (the Arduino), known by the board's client id and
# the button's key. LocalButtons::Press saves it on its first press; its rules decide what a press does.
class LocalButton < ApplicationRecord
  BUTTON = "button"
  TOGGLE = "toggle"
  GESTURES = { BUTTON => [ ButtonRule::SINGLE, ButtonRule::DOUBLE ], TOGGLE => [ ButtonRule::ON, ButtonRule::OFF ] }.freeze
  KINDS = GESTURES.keys.freeze

  has_many :rules, -> { order(:position, :id) }, class_name: "ButtonRule", inverse_of: :local_button, dependent: :delete_all

  normalizes :name, with: ->(name) { name.strip.presence }

  validates :client, :key, presence: true
  validates :key, uniqueness: { scope: :client }
  validates :kind, inclusion: { in: KINDS }

  # Unnamed buttons first, so one pressed for the first time is easy to find.
  scope :arranged, -> { order(Arel.sql("name IS NULL DESC"), :name, :key) }

  def self.gesture?(kind, gesture) = GESTURES.fetch(kind, []).include?(gesture)

  def gestures = GESTURES.fetch(kind)
  def toggle? = kind == TOGGLE
  def rules_for(gesture) = rules.select { |rule| rule.gesture == gesture }

  def first_press? = presses_count == 1
  def unnamed? = name.nil?
  def display_name = name || key
end

# == Schema Information
#
# Table name: local_buttons
#
#  id              :integer          not null, primary key
#  client          :string           not null
#  key             :string           not null
#  kind            :string           default("button"), not null
#  last_pressed_at :datetime
#  name            :string
#  presses_count   :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_local_buttons_on_client_and_key  (client,key) UNIQUE
#
