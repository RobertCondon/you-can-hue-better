module Hue
  module Payloads
    class Group < Resource
      CHILDREN_FIELD = "children"

      def child_ids(of_type:) = referenced_ids(raw[CHILDREN_FIELD], of_type:)
    end
  end
end
