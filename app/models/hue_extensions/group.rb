module HueExtensions
  class Group < Record
    FLOOR_ASPECT_RANGE = 0.4..2.5

    belongs_to :hue_group, class_name: "Hue::Group", foreign_key: :id, inverse_of: :extension

    validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :nickname, length: { maximum: MAX_NICKNAME_LENGTH }, allow_nil: true
    validates :floor_aspect, numericality: { in: FLOOR_ASPECT_RANGE }

    def self.set_hidden!(id, hidden)
      find_or_initialize_by(id:).update!(hidden: cast_boolean(hidden))
    end

    def self.set_floor_aspect!(id, aspect)
      find_or_initialize_by(id:).update!(floor_aspect: aspect.to_f.clamp(FLOOR_ASPECT_RANGE))
    end

    def self.set_order!(group_ids)
      transaction do
        where.not(id: group_ids).update_all(position: nil)
        group_ids.each_with_index { |group_id, position| find_or_initialize_by(id: group_id).update!(position:) }
      end
    end
  end
end
