module Hue
  module Api
    module Resources
      module Updatable
        def update(resource_id, changes) = command(resource_id, changes)
      end
    end
  end
end
