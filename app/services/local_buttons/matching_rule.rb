module LocalButtons
  class MatchingRule
    def self.call(button, gesture) = new(button, gesture).call

    def initialize(button, gesture)
      @button = button
      @gesture = gesture
    end

    def call = @button.rules_for(@gesture).find { |rule| rule.runnable? && rule.matches? }
  end
end
