module Hue
  class Scene < Record
    SCENE = "scene"
    SMART_SCENE = "smart_scene"
    KINDS = [ SCENE, SMART_SCENE ].freeze

    belongs_to :group
    has_many :actions, class_name: "Hue::SceneAction", dependent: :delete_all
    has_many :binding_steps, class_name: "::ControlBindingStep", as: :scene, dependent: :destroy
    has_one :extension, class_name: "::HueExtensions::Scene", foreign_key: :id, inverse_of: :hue_scene, dependent: :destroy

    validates :name, presence: true
    validates :kind, inclusion: { in: KINDS }

    scope :recallable, -> { where(kind: "scene") }

    def display_name = extension&.nickname.presence || name
    def playing?     = active == "dynamic_palette"
    def active?      = active != "inactive"
    def dynamic?     = palette_colours.any? || palette_whites.any?

    # Columns derived from the bridge's resource. Called by Sync and by the Mirror on scene events.
    def assign_from_raw(json)
      self.raw = json
      self.name = json.dig("metadata", "name") if json.dig("metadata", "name")
      self.image_id = json.dig("metadata", "image", "rid") if json.dig("metadata")&.key?("image")
      self.palette = json["palette"] if json.key?("palette")
      self.speed = json["speed"] if json.key?("speed")
      self.auto_dynamic = json["auto_dynamic"] if json.key?("auto_dynamic")
      self.active = json.dig("status", "active") if json.dig("status", "active")
      # The bridge sends last_recall as a timestamp once recalled, but as {"source": ...} on some firmware.
      self.last_recalled_at = json.dig("status", "last_recall") if json.dig("status", "last_recall").is_a?(String)
      self.last_actions_update = json["last_actions_update"] if json["last_actions_update"].is_a?(String)
      self
    end

    # One row per light, from raw.actions. Lights the mirror doesn't know are skipped.
    def rebuild_actions!
      known = Light.where(id: raw["actions"].to_a.map { _1.dig("target", "rid") }).pluck(:id).to_set
      rows = raw["actions"].to_a.filter_map do |a|
        light_id = a.dig("target", "rid")
        next unless known.include?(light_id)
        act = a["action"] || {}
        { scene_id: id, light_id:, on: act.dig("on", "on") != false, brightness: act.dig("dimming", "brightness"),
          color_x: act.dig("color", "xy", "x"), color_y: act.dig("color", "xy", "y"), mirek: act.dig("color_temperature", "mirek") }
      end
      transaction do
        actions.delete_all
        SceneAction.insert_all(rows) if rows.any?
      end
      actions.reset
    end

    # Palette entries as hex, for the card's gradient.
    def palette_colours = palette.fetch("color", []).map { |c| Hue::Color.xy_to_hex(c.dig("color", "xy", "x"), c.dig("color", "xy", "y")) }
    def palette_whites  = palette.fetch("color_temperature", []).map { |c| Hue::Color.mirek_to_hex(c.dig("color_temperature", "mirek")) }
    def palette_hexes   = palette_colours + palette_whites

    # Other rooms this stock scene was added to.
    def siblings = image_id ? Scene.recallable.where(image_id:).where.not(id:).includes(group: :extension) : Scene.none
  end
end
