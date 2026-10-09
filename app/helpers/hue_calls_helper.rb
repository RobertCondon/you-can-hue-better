module HueCallsHelper
  def hue_tab = @hue_tab ||= SecureRandom.uuid

  def hue_tab_stream = HouseBroadcast.tab_stream(hue_tab)
end
