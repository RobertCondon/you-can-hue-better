module Hue
  module Api
    module Resources
      module Renamable
        def rename(resource_id, name) = command(resource_id, { metadata: { name: } })
      end
    end
  end
end
