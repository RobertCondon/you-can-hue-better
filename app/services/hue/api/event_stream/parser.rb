module Hue
  module Api
    class EventStream
      class Parser
        MESSAGE_SEPARATOR = "\n\n"
        COMMENT_LINE = /\A:(?<text>.*)/
        ID_LINE = /\Aid:\s?(?<text>.*)/
        DATA_LINE = /\Adata:\s?(?<text>.*)/

        def initialize
          @buffer = +""
        end

        def feed(chunk)
          @buffer << chunk
          while (separator_index = @buffer.index(MESSAGE_SEPARATOR))
            yield parse(@buffer.slice!(0, separator_index + MESSAGE_SEPARATOR.length))
          end
        end

        private

        def parse(raw_message)
          id = nil
          comment = nil
          data = +""
          raw_message.each_line(chomp: true) do |line|
            case line
            when COMMENT_LINE then comment = Regexp.last_match(:text).strip
            when ID_LINE then id = Regexp.last_match(:text)
            when DATA_LINE then data << Regexp.last_match(:text)
            end
          end
          Message.new(id:, data:, comment:)
        end
      end
    end
  end
end
