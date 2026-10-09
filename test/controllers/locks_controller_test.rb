require "test_helper"

class LocksControllerTest < ActionDispatch::IntegrationTest
  test "it answers which of the asked-about lights are still locked" do
    claim = Hue::Locks.claim(%w[l1])
    get locks_path, params: { light_ids: %w[l1 l2] }, as: :json
    assert_response :success
    assert_equal({ "locked" => %w[l1] }, response.parsed_body)
  ensure
    Hue::Locks.release(claim)
  end

  test "no lights asked about means none locked" do
    get locks_path, as: :json
    assert_equal({ "locked" => [] }, response.parsed_body)
  end
end
