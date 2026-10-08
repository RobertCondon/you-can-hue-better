module ScenesHelper
  GRADIENT_DIRECTION = "90deg"
  GRADIENT_SEPARATOR = ", "
  MINIMUM_GRADIENT_COLOURS = 2

  def palette_style(hexes)
    return if hexes.size < MINIMUM_GRADIENT_COLOURS

    css_variables(palette: "linear-gradient(#{GRADIENT_DIRECTION}, #{hexes.join(GRADIENT_SEPARATOR)})")
  end

  def sibling_room_names(scene) = scene.siblings.map { |sibling| sibling.group.display_name }

  def scene_light_name(action) = action.light.extension&.nickname.presence || action.light.name
end
