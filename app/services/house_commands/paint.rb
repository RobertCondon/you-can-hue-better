module HouseCommands
  class Paint < Command
    ACTIVITY_KIND = "floor"
    ACTIVITY_ID = "paint"
    ACTIVITY_NAME = "Paint"
    LIGHT_ID_KEY = "light_id"
    HEX_KEY = "hex"
    MIREK_KEY = "mirek"

    Stroke = Data.define(:light_id, :hex, :mirek) do
      def change = mirek.present? ? Hue::Api::LightChange.white(mirek) : Hue::Api::LightChange.colour(hex)
    end

    def initialize(raw_strokes)
      @strokes = Array(JSON.parse(raw_strokes)).map do |raw_stroke|
        stroke = raw_stroke.transform_keys(&:to_s)
        Stroke.new(light_id: stroke[LIGHT_ID_KEY], hex: stroke[HEX_KEY], mirek: stroke[MIREK_KEY])
      end
    end

    def painted_light_ids = @painted_light_ids ||= Hue::Light.where(id: @strokes.map(&:light_id).uniq).pluck(:id)

    def check_request!
      raise Hue::Error, I18n.t("house_commands.paint.nothing_to_paint") if painted_light_ids.empty?
    end

    def light_ids = painted_light_ids

    def unreachable_description = Toasts.a_painted_light

    private

    def activity
      { target_kind: ACTIVITY_KIND, target_id: ACTIVITY_ID, target_name: ACTIVITY_NAME,
        action: "#{ACTIVITY_ID} #{painted_light_ids.size}", payload: @strokes.map(&:to_h) }
    end

    def send_to_bridge
      Hue::Api::CommandResult.combine(painted_strokes.map { |stroke| Hue.client.lights.update(stroke.light_id, stroke.change.to_payload) })
    end

    def catch_up_mirror
      Hue.wait_for_bridge
      read_back_lights(painted_light_ids)
    end

    def painted_strokes = @strokes.select { |stroke| painted_light_ids.include?(stroke.light_id) }
  end
end
