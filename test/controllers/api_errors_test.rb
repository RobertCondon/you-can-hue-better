require "test_helper"

class ApiErrorsTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "an unknown light is a JSON 404" do
    patch light_path("nope"), params: { light: { on: false } }, as: :json
    assert_response :not_found
    assert_predicate response.parsed_body["error"], :present?
  end

  test "a press with nothing to send is a JSON 422 that says why" do
    patch light_path("l1"), params: { light: { name: "x" } }, as: :json
    assert_response :unprocessable_entity
    assert_equal I18n.t("house_commands.light_update.nothing_to_change"), response.parsed_body["error"]
  end

  test "a press with no fields at all is a JSON 422" do
    patch light_path("l1"), params: {}, as: :json
    assert_response :unprocessable_entity
  end

  test "with no bridge set up the API says so instead of redirecting" do
    unconfigure_bridge
    patch light_path("l1"), params: { light: { on: false } }, as: :json
    assert_response :service_unavailable
    assert_equal I18n.t("api.no_bridge"), response.parsed_body["error"]
  end

  test "replies are JSON even when the caller asks for HTML" do
    patch light_path("l1"), params: { light: { on: false } }
    assert_equal "application/json", response.media_type
  end
end
