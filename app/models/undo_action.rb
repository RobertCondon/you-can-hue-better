# The states a set of lights had before a room or scene action, kept for an hour so one tap can put
# them back. States are the mirror's rows at the moment of capture.
class UndoAction < ApplicationRecord
  KEEP_FOR = 1.hour

  validates :description, presence: true

  scope :fresh, -> { where("created_at > ?", KEEP_FOR.ago) }

  def self.capture(description, light_ids)
    where("created_at <= ?", KEEP_FOR.ago).delete_all
    states = Hue::Light.where(id: light_ids).includes(:device).map do |l|
      { light_id: l.id, name: l.name, on: l.on, brightness: l.brightness.to_f,
        color_x: l.color_x&.to_f, color_y: l.color_y&.to_f, mirek: l.mirek,
        ct: l.raw.dig("color_temperature", "mirek_valid") == true }
    end
    create!(description:, states:)
  end

  # One command per light, through the same client the dashboard uses.
  def apply!(client = Hue.client)
    states.each do |s|
      body = { on: { on: s["on"] } }
      if s["on"]
        body[:dimming] = { brightness: s["brightness"] } if s["brightness"].to_f.positive?
        if s["ct"] && s["mirek"] then body[:color_temperature] = { mirek: s["mirek"] }
        elsif s["color_x"] then body[:color] = { xy: { x: s["color_x"], y: s["color_y"] } }
        end
      end
      client.set_light(s["light_id"], body)
    end
  end

  def light_count = states.size
end
