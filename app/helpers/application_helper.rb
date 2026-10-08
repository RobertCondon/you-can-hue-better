module ApplicationHelper
  THEME_COLOR = "#1c2130"
  FONT_STYLESHEET = "https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,300..700&display=swap"
  FONT_HOSTS = %w[https://fonts.googleapis.com https://fonts.gstatic.com].freeze

  def targets = HouseBroadcast::Targets

  def clock_time(time) = l(time.in_time_zone, format: :clock)

  def css_variables(variables) = variables.map { |name, value| "--#{name.to_s.dasherize}: #{value}" }.join("; ")
end
