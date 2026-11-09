module ButtonRules
  # Turns the rule form's fields into the rule's columns: each room-or-light menu sends one SubjectKey
  # and fills a type and an id column.
  class Fields
    MENUS = { if_subject: %i[if_subject_type if_subject_id], target: %i[target_type target_id] }.freeze

    def self.call(params) = new(params).call

    def initialize(params)
      @params = params.to_h.symbolize_keys
    end

    def call
      @params.each_with_object({}) do |(name, value), fields|
        if MENUS.key?(name)
          type_column, id_column = MENUS.fetch(name)
          fields[type_column], fields[id_column] = SubjectKey.load(value)
        else
          fields[name] = value
        end
      end
    end
  end
end
