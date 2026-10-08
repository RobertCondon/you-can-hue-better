module Hue
  module Resources
    module Renamable
      MAX_NAME_LENGTH = 32

      def rename(resource_id, name) = command(resource_id, { metadata: { name: } })
    end
  end
end
