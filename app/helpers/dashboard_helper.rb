module DashboardHelper
  FAILED_CLASS = "failed"
  PENDING_CLASS = "pending"

  def press_description(control_event)
    gesture = control_event.gesture.humanize.downcase
    control_event.rotation_steps ? t("dashboard.presses.with_steps", gesture:, steps: control_event.rotation_steps) : gesture
  end

  def activity_class(activity)
    return "" if activity.ok?

    activity.pending? ? PENDING_CLASS : FAILED_CLASS
  end
end
