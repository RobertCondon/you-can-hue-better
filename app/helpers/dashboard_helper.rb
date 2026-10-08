module DashboardHelper
  FAILED_CLASS = "failed"

  def press_description(control_event)
    gesture = control_event.gesture.humanize.downcase
    control_event.rotation_steps ? t("dashboard.presses.with_steps", gesture:, steps: control_event.rotation_steps) : gesture
  end

  def activity_class(activity) = activity.ok? ? "" : FAILED_CLASS
end
