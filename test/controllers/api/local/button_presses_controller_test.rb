require "test_helper"
require "turbo/broadcastable/test_helper"

class Api::Local::ButtonPressesControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  SECRET = "board-secret-0123456789abcdef0123456789abcdef"

  setup do
    @previous_clients = ENV[MachineToken::CLIENTS_VARIABLE]
    ENV[MachineToken::CLIENTS_VARIABLE] = "hall-board:#{SECRET}, script:other-secret-0123456789abcdef0123"
  end

  teardown { ENV[MachineToken::CLIENTS_VARIABLE] = @previous_clients }

  test "accepts a press signed by a known client" do
    press token

    assert_response :accepted
    assert_equal({ "button_id" => "button-1", "gesture" => "single", "rule_id" => nil }, response.parsed_body)
  end

  test "saves a button on its first press and counts the presses after" do
    2.times { press token }

    button = LocalButton.find_by!(client: "hall-board", key: "button-1")
    assert_equal 2, button.presses_count
    assert_not_nil button.last_pressed_at
  end

  test "runs the first rule whose condition holds, logged as a button press" do
    sync_mirror!
    button = LocalButton.create!(client: "hall-board", key: "button-1")
    button.rules.create!(gesture: "single", if_group_id: "r1", if_state: "off", action: "turn_on", target_group_id: "r1")
    otherwise = button.rules.create!(gesture: "single", action: "turn_off", target_group_id: "r1")

    press token

    assert_response :accepted
    assert_equal otherwise.id, response.parsed_body["rule_id"]
    assert_equal [ [ :grouped_light, "g1", { on: { on: false }, dynamics: { duration: 100 } } ] ], hue.writes
    assert_equal [ Activity::BUTTON, "off", "Study" ], [ Activity.last.source, Activity.last.action, Activity.last.target_name ]
  end

  test "a second press sees the room the first one turned off" do
    sync_mirror!
    button = LocalButton.create!(client: "hall-board", key: "button-1")
    turn_on = button.rules.create!(gesture: "single", if_group_id: "r1", if_state: "off", action: "turn_on", target_group_id: "r1")
    button.rules.create!(gesture: "single", action: "turn_off", target_group_id: "r1")

    press token
    press token

    assert_equal turn_on.id, response.parsed_body["rule_id"]
    assert_equal [ false, true ], hue.writes.map { |write| write.last.dig(:on, :on) }
  end

  test "toggle turns a lit room off" do
    sync_mirror!
    LocalButton.create!(client: "hall-board", key: "button-1").rules.create!(gesture: "single", action: "toggle", target_group_id: "r1")

    press token

    assert_equal false, hue.writes.sole.last.dig(:on, :on)
  end

  test "a double press runs the double rules" do
    sync_mirror!
    button = LocalButton.create!(client: "hall-board", key: "button-1")
    button.rules.create!(gesture: "single", action: "turn_off", target_group_id: "r1")
    button.rules.create!(gesture: "double", action: "recall_scene", target_group_id: "r1", scene_id: "s1")

    press token, gesture: "double"

    assert_equal [ [ :scene, "s1", Hue::Api::SceneRecall::STATIC_LOOK ] ], hue.writes
  end

  test "skips a rule whose room has gone from the bridge" do
    sync_mirror!
    button = LocalButton.create!(client: "hall-board", key: "button-1")
    button.rules.create!(gesture: "single", action: "turn_off", target_group_id: "gone")
    fallback = button.rules.create!(gesture: "single", action: "turn_on", target_group_id: "r1")

    press token

    assert_equal fallback.id, response.parsed_body["rule_id"]
  end

  test "a press no rule matches changes nothing" do
    press token

    assert_response :accepted
    assert_empty hue.writes
  end

  test "refuses a gesture it doesn't know, without counting the press" do
    press token, gesture: "triple"

    assert_response :unprocessable_entity
    assert_not LocalButton.exists?
  end

  test "adds a new button to open Buttons pages, then replaces its card on later presses" do
    first = capture_turbo_stream_broadcasts(LocalButtons::Broadcast::STREAM) { press token }
    later = capture_turbo_stream_broadcasts(LocalButtons::Broadcast::STREAM) { press token }

    assert_equal [ [ "prepend", HouseBroadcast::Targets.local_buttons ] ], first.map { |stream| [ stream["action"], stream["target"] ] }
    assert_equal [ "replace" ], later.map { |stream| stream["action"] }
    assert_includes later.sole.to_html, "is-pressed"
  end

  test "needs no CSRF token or session" do
    with_forgery_protection { press token }

    assert_response :accepted
  end

  test "refuses a press with no token" do
    post api_local_button_press_path, params: { button_id: "button-1" }, as: :json

    assert_response :unauthorized
    assert_equal I18n.t("api.unauthorized"), response.parsed_body["error"]
  end

  test "refuses a token signed with the wrong secret" do
    press token(secret: "not-the-secret")

    assert_response :unauthorized
  end

  test "refuses a client that is not configured" do
    press token(iss: "stranger")

    assert_response :unauthorized
  end

  test "refuses a client that has been removed, even with a token it signed before" do
    signed = token
    ENV[MachineToken::CLIENTS_VARIABLE] = "script:other-secret-0123456789abcdef0123"

    press signed

    assert_response :unauthorized
  end

  test "refuses an expired token" do
    press token(iat: 10.minutes.ago.to_i, exp: 9.minutes.ago.to_i)

    assert_response :unauthorized
  end

  test "refuses a token that would live longer than the maximum" do
    press token(exp: 1.hour.from_now.to_i)

    assert_response :unauthorized
  end

  test "refuses a token issued in the future" do
    press token(iat: 10.minutes.from_now.to_i, exp: 11.minutes.from_now.to_i)

    assert_response :unauthorized
  end

  test "refuses a token without an expiry" do
    press token(exp: nil)

    assert_response :unauthorized
  end

  test "refuses an unsigned token" do
    press JWT.encode({ iss: "hall-board", iat: Time.now.to_i, exp: 1.minute.from_now.to_i }, nil, "none")

    assert_response :unauthorized
  end

  test "allows a little clock drift on the board" do
    press token(iat: 20.seconds.from_now.to_i, exp: 80.seconds.from_now.to_i)

    assert_response :accepted
  end

  test "asks for a button id" do
    post api_local_button_press_path, params: {}, headers: auth(token), as: :json

    assert_response :unprocessable_entity
  end

  private

  def token(secret: SECRET, **claims)
    now = Time.now.to_i
    payload = { iss: "hall-board", iat: now, exp: now + 60 }.merge(claims).compact
    JWT.encode(payload, secret, "HS256")
  end

  def press(jwt, **fields) = post(api_local_button_press_path, params: { button_id: "button-1", **fields }, headers: auth(jwt), as: :json)

  def auth(jwt) = { "Authorization" => "Bearer #{jwt}" }

  def with_forgery_protection
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
