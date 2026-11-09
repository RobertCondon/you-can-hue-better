module ButtonRules
  # Whether a light is on, or a room has any light on.
  class Lit
    def self.call(subject) = new(subject).call

    def initialize(subject)
      @subject = subject
    end

    def call = @subject.is_a?(Hue::Light) ? @subject.on? : @subject.lights.any?(&:on?)
  end
end
