module ButtonRules
  # The house command a rule runs: the same commands the Lights page uses for a room or a light.
  class Command
    def self.call(rule) = new(rule).call

    def initialize(rule)
      @rule = rule
    end

    def call = @rule.targets_room? ? room_command(@rule.target) : light_command(@rule.target)

    private

    def room_command(group)
      case @rule.action
      when ButtonRule::TURN_ON then HouseCommands::RoomSwitch.new(group, on: true)
      when ButtonRule::TURN_OFF then HouseCommands::RoomSwitch.new(group, on: false)
      when ButtonRule::TOGGLE then HouseCommands::RoomSwitch.new(group, on: !Lit.call(group))
      when ButtonRule::SET_BRIGHTNESS then HouseCommands::RoomBrightness.new(group, @rule.brightness)
      when ButtonRule::RECALL_SCENE then HouseCommands::SceneRecall.new(@rule.scene, Hue::Api::SceneRecall::STATIC_LOOK)
      end
    end

    def light_command(light)
      fields = case @rule.action
      when ButtonRule::TURN_ON then { on: true }
      when ButtonRule::TURN_OFF then { on: false }
      when ButtonRule::TOGGLE then { on: !light.on? }
      when ButtonRule::SET_BRIGHTNESS then { brightness: @rule.brightness }
      end
      HouseCommands::LightUpdate.new(light, fields)
    end
  end
end
