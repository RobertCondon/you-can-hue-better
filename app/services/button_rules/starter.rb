module ButtonRules
  # The attributes "Add a rule" starts with. The first in a list turns a room on when it's off, and
  # later ones turn the same room off, so two clicks give a working on/off button.
  class Starter
    def self.call(button, gesture) = new(button, gesture).call

    def initialize(button, gesture)
      @button = button
      @gesture = gesture
    end

    def call
      last = @button.rules_for(@gesture).last
      return { gesture: @gesture, action: ButtonRule::TURN_OFF, target_type: last.target_type, target_id: last.target_id } if last

      room_id = Hue::Group.where(kind: Choices::ROOM_KINDS).order(:kind, :name).pick(:id) # rooms before zones
      { gesture: @gesture, if_subject_type: ButtonRule::ROOM, if_subject_id: room_id, if_state: ButtonRule::OFF,
        action: ButtonRule::TURN_ON, target_type: ButtonRule::ROOM, target_id: room_id }
    end
  end
end
