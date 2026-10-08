require "test_helper"

class Hue::EventStreamTest < ActiveSupport::TestCase
  test "parses keepalives and events across chunk boundaries" do
    parser = Hue::EventStream::Parser.new
    seen = []
    parser.feed(": hi\n\nid: 1:0\ndata: [{\"a\"") { |e| seen << e }
    parser.feed(":1}]\n\nid: 2:0\ndata: [{\"b\":2}]\n\n") { |e| seen << e }
    assert_equal 3, seen.size
    assert_equal "hi", seen[0][:comment]
    assert_equal [ "1:0", '[{"a":1}]' ], [ seen[1][:id], seen[1][:data] ]
    assert_equal [ "2:0", '[{"b":2}]' ], [ seen[2][:id], seen[2][:data] ]
  end
end
