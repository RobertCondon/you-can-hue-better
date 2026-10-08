class LegacyRulesImport
  class Rule
    CONDITIONS_FIELD = "conditions"
    ACTIONS_FIELD = "actions"
    ADDRESS_FIELD = "address"
    OPERATOR_FIELD = "operator"
    VALUE_FIELD = "value"
    BODY_FIELD = "body"
    EQUALS = "eq"
    GREATER_THAN = "gt"
    LESS_THAN = "lt"
    BUTTON_CODE_DIVISOR = 1000
    HOLD_EVENT = 1

    Condition = Data.define(:address, :operator, :value)
    Action = Data.define(:address, :body)
    ButtonPress = Data.define(:sensor_id, :button_number, :hold)

    attr_reader :id, :conditions, :actions

    def initialize(id, raw_rule)
      @id = id
      @conditions = raw_rule[CONDITIONS_FIELD].map { |raw| Condition.new(address: raw[ADDRESS_FIELD], operator: raw[OPERATOR_FIELD], value: raw[VALUE_FIELD]) }
      @actions = raw_rule[ACTIONS_FIELD].map { |raw| Action.new(address: raw[ADDRESS_FIELD], body: raw[BODY_FIELD]) }
    end

    def button_press
      condition = condition_matching(Addresses::BUTTON_EVENT, operator: EQUALS) or return
      button_code = condition.value.to_i
      ButtonPress.new(
        sensor_id: condition.address[Addresses::BUTTON_EVENT, 1],
        button_number: button_code / BUTTON_CODE_DIVISOR,
        hold: button_code % BUTTON_CODE_DIVISOR == HOLD_EVENT
      )
    end

    def rotation_sensor_id = condition_matching(Addresses::EXPECTED_ROTATION)&.address&.[](Addresses::EXPECTED_ROTATION, 1)

    def status_gate = condition_matching(Addresses::STATUS_CONDITION, operator: EQUALS)&.value&.to_i

    def rotation_above = condition_matching(Addresses::EXPECTED_ROTATION, operator: GREATER_THAN)&.value&.to_i

    def rotation_below = condition_matching(Addresses::EXPECTED_ROTATION, operator: LESS_THAN)&.value&.to_i

    def only_when_group_off? = conditions.any? { |condition| condition.address.end_with?(Addresses::ANY_ON_SUFFIX) && condition.value == "false" }

    def conditioned_on?(address) = conditions.any? { |condition| condition.address == address }

    def action_matching(pattern) = actions.find { |action| pattern.match?(action.address) }

    private

    def condition_matching(pattern, operator: nil)
      conditions.find { |condition| pattern.match?(condition.address) && (operator.nil? || condition.operator == operator) }
    end
  end
end
