require "test_helper"

class ControllerSplitTest < ActiveSupport::TestCase
  FRAMEWORK_CONTROLLERS = %r{\A(rails|action_mailbox|active_storage|turbo)/}
  HTML_NAMESPACE = "html/"

  def routed_controllers
    Rails.application.routes.routes.filter_map { |route| route.defaults[:controller] }.uniq.grep_v(FRAMEWORK_CONTROLLERS)
  end

  def controller_class(path) = "#{path.camelize}Controller".constantize

  test "every routed controller outside Html:: is a JSON API" do
    api_paths = routed_controllers.reject { |path| path.start_with?(HTML_NAMESPACE) }
    assert_not_empty api_paths
    assert_empty api_paths.reject { |path| controller_class(path) < ApiController }
  end

  test "every Html:: controller renders HTML from the Html base" do
    html_paths = routed_controllers.select { |path| path.start_with?(HTML_NAMESPACE) }
    assert_not_empty html_paths
    assert_empty html_paths.reject { |path| controller_class(path) < Html::ApplicationController }
  end
end
