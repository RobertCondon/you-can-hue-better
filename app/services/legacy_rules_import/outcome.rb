class LegacyRulesImport
  class Outcome
    Skip = Data.define(:rule_ids, :reason)
    Result = Data.define(:bindings, :skipped)

    def initialize
      @bindings = []
      @skipped = []
    end

    def save_binding(control:, gesture:, action:, target:, settings: {}, scenes: nil)
      binding = ControlBinding.find_or_initialize_by(control:, gesture:)
      binding.update!(action:, target:, settings:, enabled: true)
      binding.replace_steps!(scenes) if scenes
      @bindings << binding
    end

    def skip(rules, reason) = @skipped << Skip.new(rule_ids: rules.map(&:id), reason:)

    def result = Result.new(bindings: @bindings, skipped: @skipped)
  end
end
