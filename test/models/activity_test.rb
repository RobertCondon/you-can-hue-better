require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  def log(result) = Activity.create!(target_kind: "light", target_id: "l1", target_name: "Desk lamp", action: "on", result:)

  test "a pending row settles to what the bridge said" do
    activity = log(Activity::PENDING)
    activity.settle!(Activity::UNREACHABLE)
    assert activity.reload.unreachable?
    refute activity.pending?
  end

  test "pending rows left over from a restart are marked as cut short" do
    leftover = log(Activity::PENDING)
    finished = log(Activity::OK)
    Activity.interrupt_pending!
    assert_equal [ Activity::INTERRUPTED, Activity::OK ], [ leftover.reload.result, finished.reload.result ]
  end
end
