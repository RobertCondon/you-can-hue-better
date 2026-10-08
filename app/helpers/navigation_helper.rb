module NavigationHelper
  CURRENT_CLASS = "is-current"
  CURRENT_PAGE = "page"

  def navigation_items = { lights: root_path, scenes: scenes_path, floor: floor_path }

  def navigation_link_class(view, current) = class_names("views__link", CURRENT_CLASS => view == current)

  def navigation_aria_current(view, current) = view == current ? CURRENT_PAGE : nil
end
