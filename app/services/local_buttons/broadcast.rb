module LocalButtons
  # Keeps an open Buttons page true. A button's first press adds its card; any other press or change
  # replaces the card; forgetting the button removes it.
  class Broadcast
    STREAM = "local_buttons"
    PARTIAL = "local_buttons/card"

    PRESSED = :pressed
    CHANGED = :changed
    REMOVED = :removed

    def self.call(button, event = CHANGED) = new(button, event).call

    def initialize(button, event)
      @button = button
      @event = event
    end

    def call
      return Turbo::StreamsChannel.broadcast_remove_to(STREAM, target: card) if @event == REMOVED
      return Turbo::StreamsChannel.broadcast_prepend_to(STREAM, target: list, partial: PARTIAL, locals:) if new_button?

      Turbo::StreamsChannel.broadcast_replace_to(STREAM, target: card, partial: PARTIAL, locals:)
    end

    private

    def new_button? = @event == PRESSED && @button.first_press?

    def locals = { button: @button, choices: ButtonRules::Choices.call, pressed: @event == PRESSED }

    def card = HouseBroadcast::Targets.local_button(@button)

    def list = HouseBroadcast::Targets.local_buttons
  end
end
