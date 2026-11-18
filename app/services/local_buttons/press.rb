module LocalButtons
  class Press
    Result = Data.define(:button, :rule)

    def self.call(client:, key:, gesture:, kind: LocalButton::BUTTON) = new(client:, key:, kind:, gesture:).call

    def initialize(client:, key:, kind:, gesture:)
      @client = client
      @key = key
      @kind = kind
      @gesture = gesture
    end

    def call
      button = record
      rule = MatchingRule.call(button, @gesture)
      Broadcast.call(button, Broadcast::PRESSED)
      run(rule) if rule
      Result.new(button:, rule:)
    end

    private

    def record
      button = LocalButton.find_or_create_by!(client: @client, key: @key) { |new_button| new_button.kind = @kind }
      LocalButton.where(id: button.id).update_all([ "presses_count = presses_count + 1, last_pressed_at = ?, kind = ?", Time.current, @kind ])
      button.reload
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def run(rule)
      reply = ButtonRules::Command.call(rule).from(Activity::BUTTON).call_later
      raise HouseCommands::LightsBusy, reply if reply.is_a?(HouseCommands::Busy)
    rescue HouseCommands::NotInstant
      nil
    end
  end
end
