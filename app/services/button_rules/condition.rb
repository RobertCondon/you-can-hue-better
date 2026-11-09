module ButtonRules
  # Whether a rule should run now: always when it checks nothing, otherwise when the room or light it
  # checks is in its state. False when what it checks, or what it changes, has gone from the bridge.
  class Condition
    def self.call(rule) = new(rule).call

    def initialize(rule)
      @rule = rule
    end

    def call
      return false unless @rule.runnable?
      return true if @rule.always?

      @rule.if_subject.present? && Lit.call(@rule.if_subject) == (@rule.if_state == ButtonRule::ON)
    end
  end
end
