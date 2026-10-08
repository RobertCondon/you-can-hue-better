class LegacyRulesImport
  def self.call(raw_rules) = new(raw_rules).call

  def initialize(raw_rules)
    @rules = raw_rules.map { |rule_id, raw_rule| Rule.new(rule_id, raw_rule) }
    @outcome = Outcome.new
  end

  def call
    import_buttons
    import_rotaries
    @outcome.result
  end

  private

  def import_buttons
    @rules.select(&:button_press).group_by(&:button_press).each do |button_press, rules|
      sensor_path = Addresses.sensor_path(button_press.sensor_id)
      control = Hue::Control.find_by(id_v1: sensor_path, kind: Hue::Control::BUTTON, control_number: button_press.button_number)
      next @outcome.skip(rules, "no control for #{sensor_path} button #{button_press.button_number}") unless control

      ButtonImporter.new(control:, hold: button_press.hold, rules:, all_rules: @rules, outcome: @outcome).import
    end
  end

  def import_rotaries
    @rules.select(&:rotation_sensor_id).group_by(&:rotation_sensor_id).each do |sensor_id, rules|
      control = Hue::Control.find_by(id_v1: Addresses.sensor_path(sensor_id), kind: Hue::Control::ROTARY)
      next @outcome.skip(rules, "no rotary control for #{Addresses.sensor_path(sensor_id)}") unless control

      RotaryImporter.new(control:, rules:, outcome: @outcome).import
    end
  end
end
