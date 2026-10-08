module ApplicationHelper
  THEME_COLOR = "#1c2130"
  FONT_STYLESHEET = "https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,300..700&display=swap"
  FONT_HOSTS = %w[https://fonts.googleapis.com https://fonts.gstatic.com].freeze
  STYLESHEETS = %w[
    tokens base header toasts rooms tiles light_panel pinned_light scenes dev
    floor floor_toolbar floor_nets floor_paint floor_objects floor_lamps editor pages
  ].freeze

  def targets = HouseBroadcast::Targets

  def clock_time(time) = l(time.in_time_zone, format: :clock)

  def css_variables(variables) = variables.map { |name, value| "--#{name.to_s.dasherize}: #{value}" }.join("; ")
end
