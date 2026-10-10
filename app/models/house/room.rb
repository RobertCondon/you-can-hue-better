class House
  class Room < Data.define(:id, :name, :kind, :grouped_light_id, :lights, :scenes, :custom_scenes, :position, :nickname, :hidden)
    def initialize(position: nil, nickname: nil, hidden: false, custom_scenes: [], **attributes)
      super(position:, nickname: nickname.presence, hidden: hidden == true, custom_scenes:, **attributes)
    end

    def display_name = nickname || name
    def nicknamed? = nickname.present?
    def hidden? = hidden
    def visible_lights = lights.reject(&:hidden?)
    def on_count = visible_lights.count(&:lit?)
    def any_on? = on_count.positive?
    def all_on? = visible_lights.all?(&:lit?)
    def lit_lights = visible_lights.select(&:lit?)

    def level
      return Light::UNLIT_LEVEL if lit_lights.empty?

      (lit_lights.sum(&:brightness) / lit_lights.size).round.clamp(Hue::Api::Limits::LIT_BRIGHTNESS)
    end

    def mixed_brightness? = lit_lights.map { |light| light.brightness.round }.uniq.size > 1

    def brightness_label
      return I18n.t("house.light.off") unless any_on?

      I18n.t(mixed_brightness? ? "house.room.mixed_level" : "house.light.level", level:)
    end

    def summary
      return I18n.t("house.room.all_off") if on_count.zero?
      return I18n.t("house.room.all_on") if all_on?

      I18n.t("house.room.some_on", on: on_count, total: visible_lights.size)
    end
  end
end
