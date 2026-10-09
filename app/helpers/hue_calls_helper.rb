module HueCallsHelper
  ASYNC_CONTROLLER = "async-hue-call"
  ASYNC_SUBMIT_ACTION = "submit->async-hue-call#submit"

  def hue_tab = @hue_tab ||= SecureRandom.uuid

  def hue_tab_stream = HouseBroadcast.tab_stream(hue_tab)

  def async_hue_form_with(light_ids:, data: {}, **options, &)
    form_with(**options, data: { **data, controller: ASYNC_CONTROLLER, action: ASYNC_SUBMIT_ACTION, async_hue_call_light_ids_value: light_ids }, &)
  end
end
