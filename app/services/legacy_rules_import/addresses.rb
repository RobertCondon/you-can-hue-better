class LegacyRulesImport
  module Addresses
    BUTTON_EVENT = %r{\A/sensors/(\d+)/state/buttonevent\z}
    EXPECTED_ROTATION = %r{\A/sensors/(\d+)/state/expectedrotation\z}
    STATUS_CONDITION = %r{\A/sensors/(\d+)/state/status\z}
    STATUS_WRITE = %r{\A/sensors/(\d+)/state\z}
    GROUP_ACTION = %r{\A/groups/(\d+)/action\z}
    LIGHT_STATE = %r{\A/lights/(\d+)/state\z}
    STATUS_SUFFIX = "/status"
    ANY_ON_SUFFIX = "any_on"

    module_function

    def sensor_path(sensor_id) = "/sensors/#{sensor_id}"
    def group_path(group_number) = "/groups/#{group_number}"
    def light_path(light_number) = "/lights/#{light_number}"
    def scene_path(scene_number) = "/scenes/#{scene_number}"

    def group_for(address)
      group_number = address[GROUP_ACTION, 1]
      Hue::Group.find_by(id_v1: group_path(group_number)) if group_number
    end

    def light_for(address)
      light_number = address[LIGHT_STATE, 1]
      Hue::Light.find_by(id_v1: light_path(light_number)) if light_number
    end

    def scene_for(scene_number) = Hue::Scene.find_by(id_v1: scene_path(scene_number))
  end
end
