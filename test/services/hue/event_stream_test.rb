require "test_helper"

class Hue::EventStreamTest < ActiveSupport::TestCase
  test "parses keepalives and events across chunk boundaries" do
    parser = Hue::EventStream::Parser.new
    messages = []
    parser.feed(": hi\n\nid: 1:0\ndata: [{\"a\"") { |message| messages << message }
    parser.feed(":1}]\n\nid: 2:0\ndata: [{\"b\":2}]\n\n") { |message| messages << message }

    assert_equal 3, messages.size
    assert messages.first.keepalive?
    assert_equal "hi", messages.first.comment
    assert_equal [ "1:0", '[{"a":1}]' ], [ messages.second.id, messages.second.data ]
    assert_equal [ "2:0", '[{"b":2}]' ], [ messages.third.id, messages.third.data ]
  end

  test "reconnects at least one heartbeat before the dashboard would call the stream stale" do
    assert_operator Hue::EventStream::READ_TIMEOUT_SECONDS, :<=, (Hue::ListenerState::LIVENESS_WINDOW - Hue::ListenerState::HEARTBEAT_EVERY).to_i
  end
end
