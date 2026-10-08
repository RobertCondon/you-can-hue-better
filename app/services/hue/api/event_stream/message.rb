module Hue
  module Api
    class EventStream
      class Message < Data.define(:id, :data, :comment)
        def keepalive? = data.blank?
      end
    end
  end
end
