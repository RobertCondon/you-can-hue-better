require "test_helper"
require "turbo/broadcastable/test_helper"

class LocalButtonsControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  setup do
    sync_mirror!
    @button = LocalButton.create!(client: "hall-board", key: "button-1", presses_count: 3, last_pressed_at: 1.hour.ago)
  end

  test "the Buttons page shows each button with its rules" do
    @button.rules.create!(gesture: ButtonRule::SINGLE, if_group_id: "r1", if_state: "off", action: "turn_on", target_group_id: "r1")

    get local_buttons_path

    assert_response :success
    assert_select "nav.views .views__link[aria-current=page]", text: "Buttons"
    card = "#local_button_#{@button.id}"
    assert_select "#{card}.is-unnamed input[name='local_button[name]'][placeholder='Name this button']"
    assert_select "#{card} .local-button__meta", /button-1 · hall-board · pressed about 1 hour ago · 3 presses/
    assert_select "#{card} .button-rule select[name='button_rule[if_group_id]'] option[selected][value=r1]", "Study"
    assert_select "#{card} .button-rule select[name='button_rule[if_state]'] option[selected][value=off]"
    assert_select "#{card} .local-button__gesture", 2
    assert_select "#{card} .local-button__nothing", "Nothing happens yet."
  end

  test "names a button and updates open pages" do
    streams = capture_turbo_stream_broadcasts(LocalButtons::Broadcast::STREAM) do
      patch local_button_path(@button), params: { local_button: { name: " Bedside " } }, as: :json
    end

    assert_response :success
    assert_equal "Bedside", @button.reload.name
    assert_equal [ [ "replace", "local_button_#{@button.id}" ] ], streams.map { |stream| [ stream["action"], stream["target"] ] }
  end

  test "a blank name leaves the button unnamed" do
    @button.update!(name: "Bedside")

    patch local_button_path(@button), params: { local_button: { name: "  " } }, as: :json

    assert_nil @button.reload.name
  end

  test "forgets a button and its rules" do
    @button.rules.create!(gesture: ButtonRule::SINGLE, action: "turn_off", target_group_id: "r1")

    streams = capture_turbo_stream_broadcasts(LocalButtons::Broadcast::STREAM) { delete local_button_path(@button), as: :json }

    assert_response :no_content
    assert_not LocalButton.exists?(@button.id)
    assert_equal 0, ButtonRule.count
    assert_equal [ "remove" ], streams.map { |stream| stream["action"] }
  end
end
