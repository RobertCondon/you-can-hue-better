require "test_helper"

class Hue::LocksTest < ActiveSupport::TestCase
  test "claiming free lights holds them until released" do
    claim = Hue::Locks.claim(%w[lamp fan])
    assert_equal %w[lamp fan], claim.light_ids
    assert Hue::Locks.locked?("lamp")
    assert Hue::Locks.locked?("fan")
  ensure
    Hue::Locks.release(claim)
  end

  test "a light that is already held bounces the whole claim" do
    first_claim = Hue::Locks.claim(%w[lamp fan])
    assert_nil Hue::Locks.claim(%w[fan desk])
    refute Hue::Locks.locked?("desk")
  ensure
    Hue::Locks.release(first_claim)
  end

  test "released lights can be claimed again" do
    Hue::Locks.release(Hue::Locks.claim(%w[lamp]))
    refute Hue::Locks.locked?("lamp")
    claim = Hue::Locks.claim(%w[lamp])
    assert claim
  ensure
    Hue::Locks.release(claim)
  end

  test "claiming no lights always succeeds and holds nothing" do
    claim = Hue::Locks.claim([])
    assert_equal [], claim.light_ids
    assert Hue::Locks.claim([])
  end

  test "releasing nothing is harmless" do
    assert_nothing_raised { Hue::Locks.release(nil) }
  end

  test "it reports which of several lights are held" do
    claim = Hue::Locks.claim(%w[lamp])
    assert_equal %w[lamp], Hue::Locks.locked_among(%w[desk lamp])
  ensure
    Hue::Locks.release(claim)
  end

  test "two threads racing for the same light give it to exactly one" do
    claims = Array.new(8) { Thread.new { Hue::Locks.claim(%w[lamp]) } }.map(&:value)
    assert_equal 1, claims.compact.size
  ensure
    claims&.compact&.each { |claim| Hue::Locks.release(claim) }
  end
end
