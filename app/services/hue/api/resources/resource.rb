module Hue
  module Api
    module Resources
      class Resource
        RESOURCE_ROOT = "/clip/v2/resource"
        PATH_SEPARATOR = "/"

        def self.resource_type = self::RESOURCE_TYPE

        def initialize(connection)
          @connection = connection
        end

        def all = fetch(path)

        def find(resource_id) = fetch(path(resource_id)).first

        private

        def fetch(resource_path) = ClipResponse.new(@connection.get(resource_path)).data

        def command(resource_id, changes) = ClipResponse.new(@connection.put(path(resource_id), changes)).command_result

        def path(resource_id = nil) = [ RESOURCE_ROOT, self.class.resource_type, resource_id ].compact.join(PATH_SEPARATOR)
      end
    end
  end
end
