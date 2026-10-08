module FloorsHelper
  SHAPES = { wide: 1.6, square: 1.0, tall: 0.7 }.freeze
  SHAPE_MATCH_TOLERANCE = 0.05
  ROTATION_STEP_DEGREES = 15
  HUE_SLIDER_RANGE = 0..359
  HUE_SLIDER_START = 300
  LAMP_CLASSES = { unplaced: "is-unplaced", muted: "is-muted" }.freeze
  PAINT_WHITES = { candle: 400, warm: 370, soft: 286, cool: 200, daylight: 153 }.freeze
  PAINT_COLOURS = %w[#ff3b30 #ff9500 #ffcc00 #34c759 #30d5c8 #0a84ff #5e5ce6 #bf5af2 #ff2d55].freeze

  def floor_script_labels
    {
      done: t("floors.script.done"), editFloor: t("floors.toolbar.edit_floor"),
      roomHint: t("floors.script.room_hint"), outlineHint: t("floors.script.outline_hint"),
      houseOutline: t("floors.toolbar.house_outline"), netName: t("floors.script.net_name"), point: t("floors.script.point"),
      painted: t("floors.script.painted"), paintInstructions: t("floors.paint_tray.instructions")
    }
  end

  def floor_shape_options(floor)
    SHAPES.map { |shape, aspect| [ t("floors.floor.shapes.#{shape}"), aspect, (floor.aspect - aspect).abs < SHAPE_MATCH_TOLERANCE ] }
  end

  def paint_whites = PAINT_WHITES.map { |white, mirek| [ t("floors.floor.whites.#{white}"), mirek, Hue::Color.mirek_to_hex(mirek) ] }

  def paint_colours = PAINT_COLOURS

  def lamp_classes(spot)
    class_names("floor__lamp", light_state_class(spot.light), LAMP_CLASSES[:unplaced] => !spot.placed, LAMP_CLASSES[:muted] => spot.muted)
  end

  def lamp_style(spot)
    light = spot.light
    css_variables(x: spot.x, y: spot.y, hue: light.hex, bri: light.glow, ink: light.tile_text_hex)
  end

  def lamp_label(spot) = "#{spot.light.display_name}, #{spot.muted ? t("floors.light.not_in_scene") : spot.light.brightness_label}"

  def item_style(item)
    css_variables(x: item.x, y: item.y, w: item.w, h: item.h, r: item.rotation)
  end

  def net_label_style(net) = css_variables(x: net.centroid.first, y: net.centroid.last)
end
