require "test_helper"

class Html::LightsControllerTest < ActionDispatch::IntegrationTest
  setup { sync_mirror! }

  test "tiles are plain and open a panel; the panel carries the colour component" do
    get root_path
    assert_select "#light_r1_l1 .tile__open[data-light-panel-pin-url-param='#{pin_html_light_path("l1")}']"
    assert_select "#light_r1_l1 input", 0, "no form controls in the row; the drag is the slider"
    assert_select "main[data-controller=light-panel]"

    get panel_html_light_path("l1")
    assert_response :success
    assert_select "#light_panel_l1[data-color-picker-mode-value=ct][data-color-picker-mirek-value='359']"
    assert_select "#light_panel_l1[data-color-picker-gamut-value*='0.6915']"
    assert_select "#light_panel_l1 .switch input[type=checkbox][checked]"
    assert_select "#light_panel_l1 input[type=range][value='80']"
    assert_select "#light_panel_l1 output", "80%"
    assert_select "#light_panel_l1 .light-panel__name[data-editor-url-param='#{light_names_path("l1")}']"
  end

  test "the panel's switch and brightness go through the async form controller" do
    get panel_html_light_path("l1")
    assert_select "#light_panel_l1 form.switch[data-controller=async-hue-call]"
    assert_select "#light_panel_l1 form.light-panel__row[data-controller=async-hue-call]"
  end
end
