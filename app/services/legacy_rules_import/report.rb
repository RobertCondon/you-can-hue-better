class LegacyRulesImport
  class Report
    CONTROL_COLUMN_WIDTH = 34
    GESTURE_COLUMN_WIDTH = 14
    ACTION_COLUMN_WIDTH = 17
    SCENE_SEPARATOR = " > "
    RULE_ID_SEPARATOR = ","

    def initialize(result)
      @result = result
    end

    def lines
      [ "#{@result.bindings.size} bindings:", *@result.bindings.map { |binding| binding_line(binding) }, *skipped_lines ]
    end

    private

    def binding_line(binding)
      columns = [
        binding.control.label.ljust(CONTROL_COLUMN_WIDTH),
        binding.gesture.ljust(GESTURE_COLUMN_WIDTH),
        binding.action.ljust(ACTION_COLUMN_WIDTH),
        "#{binding.target&.name}#{scene_list(binding)}",
        binding.settings.presence
      ]
      "  #{columns.join(" ")}"
    end

    def scene_list(binding)
      binding.steps.any? ? " [#{binding.scenes.map(&:name).join(SCENE_SEPARATOR)}]" : ""
    end

    def skipped_lines
      return [] if @result.skipped.empty?

      [ "#{@result.skipped.size} rule groups skipped:", *@result.skipped.map { |skip| "  rules #{skip.rule_ids.join(RULE_ID_SEPARATOR)}: #{skip.reason}" } ]
    end
  end
end
