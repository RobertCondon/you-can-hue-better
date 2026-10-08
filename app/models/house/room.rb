class House
  class Room < Data.define(:id, :name, :kind, :grouped_light_id, :lights, :scenes, :position, :nickname, :hidden)
    def initialize(position: nil, nickname: nil, hidden: false, **attributes)
      super(position:, nickname: nickname.presence, hidden: hidden == true, **attributes)
    end

    def display_name = nickname || name
    def nicknamed? = nickname.present?
    def hidden? = hidden
    def visible_lights = lights.reject(&:hidden?)
    def on_count = visible_lights.count(&:lit?)
    def any_on? = on_count.positive?
    def all_on? = visible_lights.all?(&:lit?)

    def summary
      return I18n.t("house.room.all_off") if on_count.zero?
      return I18n.t("house.room.all_on") if all_on?

      I18n.t("house.room.some_on", on: on_count, total: visible_lights.size)
    end
  end
end
