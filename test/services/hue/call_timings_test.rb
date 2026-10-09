require "test_helper"

class Hue::CallTimingsTest < ActiveSupport::TestCase
  test "it answers the default until there are enough calls" do
    kind = unique_kind
    (Hue::CallTimings::MINIMUM_SAMPLES - 1).times { Hue::CallTimings.record(kind, 0.5) }
    assert_equal Hue::CallTimings::DEFAULT_MILLISECONDS, Hue::CallTimings.p95_milliseconds(kind)
  end

  test "it answers the 95th percentile of recent calls" do
    kind = unique_kind
    (1..100).each { |hundredths| Hue::CallTimings.record(kind, hundredths / 100.0) }
    assert_equal 950, Hue::CallTimings.p95_milliseconds(kind)
  end

  test "it never answers less than the floor" do
    kind = unique_kind
    Hue::CallTimings::MINIMUM_SAMPLES.times { Hue::CallTimings.record(kind, 0.01) }
    assert_equal Hue::CallTimings::FLOOR_MILLISECONDS, Hue::CallTimings.p95_milliseconds(kind)
  end

  test "it never answers more than the bridge connection's timeouts" do
    kind = unique_kind
    Hue::CallTimings::MINIMUM_SAMPLES.times { Hue::CallTimings.record(kind, 60) }
    assert_equal Hue::CallTimings::CEILING_MILLISECONDS, Hue::CallTimings.p95_milliseconds(kind)
  end

  test "only the most recent calls count" do
    kind = unique_kind
    Hue::CallTimings::WINDOW.times { Hue::CallTimings.record(kind, 5) }
    Hue::CallTimings::WINDOW.times { Hue::CallTimings.record(kind, 0.4) }
    assert_equal 400, Hue::CallTimings.p95_milliseconds(kind)
  end

  test "each kind of call is measured on its own" do
    slow_kind, fast_kind = unique_kind, unique_kind
    Hue::CallTimings::MINIMUM_SAMPLES.times { Hue::CallTimings.record(slow_kind, 0.7) }
    Hue::CallTimings::MINIMUM_SAMPLES.times { Hue::CallTimings.record(fast_kind, 0.3) }
    assert_equal [ 700, 300 ], [ Hue::CallTimings.p95_milliseconds(slow_kind), Hue::CallTimings.p95_milliseconds(fast_kind) ]
  end

  test "measuring records the call even when it fails" do
    kind = unique_kind
    assert_raises(Hue::Error) { Hue::CallTimings.measure(kind) { raise Hue::Error, "no bridge" } }
    assert_equal 1, Hue::CallTimings::SAMPLES[kind].size
  end

  private

  def unique_kind = :"test_#{SecureRandom.hex(4)}"
end
