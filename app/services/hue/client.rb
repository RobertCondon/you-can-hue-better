module Hue
  class Client
    def initialize(config = Config.load, connection: PersistentConnection.new(config))
      @connection = connection
    end

    def lights = @lights ||= Resources::Lights.new(@connection)
    def grouped_lights = @grouped_lights ||= Resources::GroupedLights.new(@connection)
    def rooms = @rooms ||= Resources::Rooms.new(@connection)
    def zones = @zones ||= Resources::Zones.new(@connection)
    def scenes = @scenes ||= Resources::Scenes.new(@connection)
    def smart_scenes = @smart_scenes ||= Resources::SmartScenes.new(@connection)
    def devices = @devices ||= Resources::Devices.new(@connection)
    def buttons = @buttons ||= Resources::Buttons.new(@connection)
    def relative_rotaries = @relative_rotaries ||= Resources::RelativeRotaries.new(@connection)
    def zigbee_connectivity = @zigbee_connectivity ||= Resources::ZigbeeConnectivity.new(@connection)
    def device_power = @device_power ||= Resources::DevicePower.new(@connection)

    def groups_of_type(group_type) = { ResourceType::ROOM => rooms, ResourceType::ZONE => zones }.fetch(group_type)
  end
end
