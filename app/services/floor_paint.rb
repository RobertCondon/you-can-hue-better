class FloorPaint
  ACTIVITY_KIND = "floor"
  ACTIVITY_ID = "paint"
  ACTIVITY_NAME = "Paint"
  LIGHT_ID_KEY = "light_id"
  HEX_KEY = "hex"
  MIREK_KEY = "mirek"
  WHITES = { candle: 400, warm: 370, soft: 286, cool: 200, daylight: 153 }.freeze
  COLOURS = %w[#ff3b30 #ff9500 #ffcc00 #34c759 #30d5c8 #0a84ff #5e5ce6 #bf5af2 #ff2d55].freeze

  Stroke = Data.define(:light_id, :hex, :mirek) do
    def changes
      return { on: { on: true }, color_temperature: { mirek: mirek.to_i.clamp(Hue::Light::MIREK_RANGE) } } if mirek.present?

      { on: { on: true }, color: { xy: Hue::Color.hex_to_xy(hex) } }
    end
  end

  attr_reader :undo, :result

  def initialize(raw_strokes)
    @strokes = Array(JSON.parse(raw_strokes)).map do |raw_stroke|
      stroke = raw_stroke.transform_keys(&:to_s)
      Stroke.new(light_id: stroke[LIGHT_ID_KEY], hex: stroke[HEX_KEY], mirek: stroke[MIREK_KEY])
    end
  end

  def painted_light_ids = @painted_light_ids ||= Hue::Light.where(id: @strokes.map(&:light_id).uniq).pluck(:id)

  def apply!
    raise Hue::Error, I18n.t("floor.paint.nothing_to_paint") if painted_light_ids.empty?

    @undo = Undo::Capture.call(I18n.t("floor.paint.description", count: painted_light_ids.size), painted_light_ids)
    @result = ActivityRecorder.record(target_kind: ACTIVITY_KIND, target_id: ACTIVITY_ID, target_name: ACTIVITY_NAME,
                                      action: "#{ACTIVITY_ID} #{painted_light_ids.size}", payload: @strokes.map(&:to_h)) { send_strokes }
  end

  def refresh_mirror!
    HouseBroadcast.changes(Hue::Mirror.apply(painted_light_ids.map { |light_id| Hue.client.lights.find(light_id) }))
  end

  private

  def send_strokes
    Hue::CommandResult.combine(@strokes.select { |stroke| painted_light_ids.include?(stroke.light_id) }.map do |stroke|
      Hue.client.lights.update(stroke.light_id, stroke.changes)
    end)
  end
end
