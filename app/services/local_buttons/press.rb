module LocalButtons
  class Press
    Result = Data.define(:button, :rule)

    def self.call(client:, key:, gesture:) = new(client:, key:, gesture:).call

    def initialize(client:, key:, gesture:)
      @client = client
      @key = key
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
      button = LocalButton.find_or_create_by!(client: @client, key: @key)
      LocalButton.where(id: button.id).update_all([ "presses_count = presses_count + 1, last_pressed_at = ?", Time.current ])
      button.reload
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def run(rule)
      reply = rule.command.from(Activity::BUTTON).call_later
      raise HouseCommands::LightsBusy, reply if reply.is_a?(HouseCommands::Busy)
    rescue HouseCommands::NotInstant
      nil
    end
  end
end
