module HueCallsHelper
  ASYNC_CONTROLLER = "async-hue-call"
  ASYNC_SUBMIT_ACTION = "submit->async-hue-call#submit hue:freed@document->async-hue-call#freed"
  DIRECT_CONTROLLER = "direct-hue-call"
  DIRECT_SUBMIT_ACTION = "submit->direct-hue-call#submit"

  def hue_tab = @hue_tab ||= SecureRandom.uuid

  def hue_tab_stream = HouseBroadcast.tab_stream(hue_tab)

  def async_hue_form_with(light_ids:, data: {}, **options, &)
    form_with(**options, data: async_hue_data(data, light_ids), &)
  end

  def async_hue_button_to(name, url, light_ids:, form: {}, **options)
    button_to(name, url, **options, form: { **form, data: async_hue_data(form.fetch(:data, {}), light_ids) })
  end

  def direct_hue_form_with(data: {}, **options, &)
    form_with(**options, data: { **data, controller: joined(DIRECT_CONTROLLER, data[:controller]), action: joined(DIRECT_SUBMIT_ACTION, data[:action]) }, &)
  end

  private

  def async_hue_data(data, light_ids)
    { **data, controller: joined(ASYNC_CONTROLLER, data[:controller]), action: joined(ASYNC_SUBMIT_ACTION, data[:action]), async_hue_call_light_ids_value: light_ids }
  end

  def joined(*tokens) = tokens.compact.join(" ")
end
