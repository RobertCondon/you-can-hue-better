module ButtonRules
  # Swaps a rule with its neighbour in its gesture's list, then numbers the list from 0.
  class Move
    def self.call(rule, direction) = new(rule, direction).call

    def initialize(rule, direction)
      @rule = rule
      @direction = direction
    end

    def call
      list = ButtonRule.where(local_button_id: @rule.local_button_id, gesture: @rule.gesture).order(:position, :id).to_a
      from = list.index(@rule)
      to = @direction == ButtonRule::UP ? from - 1 : from + 1
      return if to.negative? || to >= list.size

      list[from], list[to] = list[to], list[from]
      ButtonRule.transaction { list.each_with_index { |rule, position| rule.update_column(:position, position) } }
    end
  end
end
