module Toasts
  module_function

  def not_responding(light_description) = I18n.t("toasts.not_responding", light: light_description)

  def lights_busy(target_name) = I18n.t("toasts.lights_busy", target: target_name)

  def went_wrong(target_name) = I18n.t("toasts.went_wrong", target: target_name)

  def a_light_in(room_name) = I18n.t("toasts.a_light_in", room: room_name)

  def a_painted_light = I18n.t("toasts.a_painted_light")
end
