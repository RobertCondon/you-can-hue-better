require "test_helper"

class HouseCommands::CommandTest < ActiveSupport::TestCase
  setup { sync_mirror! }

  def lamp_update(on: "false") = HouseCommands::LightUpdate.new(Hue::Light.find("l1"), ActionController::Parameters.new(on:).permit!)

  test "calling later hands back the lights and a time to check in" do
    accepted = lamp_update.call_later
    assert_equal %w[l1], accepted.light_ids
    assert_includes Hue::CallTimings::FLOOR_MILLISECONDS..Hue::CallTimings::CEILING_MILLISECONDS, accepted.check_in_milliseconds
    refute Hue::Locks.locked?("l1")
  end

  test "calling later on locked lights is busy and sends nothing" do
    claim = Hue::Locks.claim(%w[l1])
    busy = lamp_update.call_later
    assert_equal [ %w[l1], "Desk lamp" ], [ busy.light_ids, busy.target_name ]
    assert_empty hue.writes
    assert_equal 0, Activity.count
  ensure
    Hue::Locks.release(claim)
  end

  test "calling now on locked lights is busy too" do
    claim = Hue::Locks.claim(%w[l1])
    assert_kind_of HouseCommands::Busy, lamp_update.call_now
    assert_empty hue.writes
  ensure
    Hue::Locks.release(claim)
  end

  test "calling now releases the lights even when the bridge says no" do
    hue.rejection_for_writes = "link button not pressed"
    assert_raises(Hue::Error) { lamp_update.call_now }
    refute Hue::Locks.locked?("l1")
  end

  test "a command that names no lights can't be called later" do
    rename = HouseCommands::RenameLight.new(Hue::Light.find("l1"), "Reading lamp")
    assert_raises(HouseCommands::NotInstant) { rename.call_later }
  end

  test "a command that names no lights never locks anything" do
    claim = Hue::Locks.claim(%w[l1])
    HouseCommands::RenameLight.new(Hue::Light.find("l1"), "Reading lamp").call_now
    assert_includes hue.writes.map(&:first), :rename_light
  ensure
    Hue::Locks.release(claim)
  end

  test "each call later is timed under its own kind" do
    assert_difference -> { Hue::CallTimings::SAMPLES[:light_update].size }, 1 do
      lamp_update.call_later
    end
  end
end
