module ButtonRules
  # The value a room-or-light menu uses for one option: "room:r1" or "light:l1".
  module SubjectKey
    PREFIXES = { "room" => ButtonRule::ROOM, "light" => ButtonRule::LIGHT }.freeze
    NONE = [ nil, nil ].freeze

    module_function

    def dump(type, id) = id.present? ? "#{PREFIXES.key(type)}:#{id}" : ""

    # [type, id], or [nil, nil] for "always" and anything it doesn't recognise.
    def load(key)
      prefix, id = key.to_s.split(":", 2)
      type = PREFIXES[prefix]
      type && id.present? ? [ type, id ] : NONE
    end
  end
end
