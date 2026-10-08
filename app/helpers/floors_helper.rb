module FloorsHelper
  SHAPES = { wide: 1.6, square: 1.0, tall: 0.7 }.freeze
  SHAPE_MATCH_TOLERANCE = 0.05
  ROTATION_STEP_DEGREES = 15
  HUE_SLIDER_RANGE = 0..359
  HUE_SLIDER_START = 300
  LAMP_CLASSES = { unplaced: "is-unplaced", muted: "is-muted" }.freeze

  def floor_shape_options(floor)
    SHAPES.map { |shape, aspect| [ t("floors.floor.shapes.#{shape}"), aspect, (floor.aspect - aspect).abs < SHAPE_MATCH_TOLERANCE ] }
  end

  def paint_whites = FloorPaint::WHITES.map { |white, mirek| [ t("floors.floor.whites.#{white}"), mirek, Hue::Color.mirek_to_hex(mirek) ] }

  def paint_colours = FloorPaint::COLOURS

  def lamp_classes(spot)
    class_names("floor__lamp", light_state_class(spot.light), LAMP_CLASSES[:unplaced] => !spot.placed, LAMP_CLASSES[:muted] => spot.muted)
  end

  def lamp_style(spot)
    light = spot.light
    css_variables(x: spot.x, y: spot.y, hue: light.hex, bri: light.glow, ink: light.tile_text_hex)
  end

  def lamp_label(spot) = "#{spot.light.display_name}, #{spot.muted ? t("floors.light.not_in_scene") : spot.light.brightness_label}"

  def object_style(floor_object)
    css_variables(x: floor_object.x, y: floor_object.y, w: floor_object.w, h: floor_object.h, r: floor_object.rotation)
  end

  def net_label_style(net) = css_variables(x: net.centroid.first, y: net.centroid.last)
end
