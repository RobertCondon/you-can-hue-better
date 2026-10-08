module HueExtensions
  # What the app knows about a room or zone that the bridge doesn't. Keyed by the Hue group id.
  # Today: its dashboard position. Later: hidden, nickname, default scene, and so on.
  class Group < Record
    belongs_to :hue_group, class_name: "Hue::Group", foreign_key: :id, inverse_of: :extension

    validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :nickname, length: { maximum: 40 }, allow_nil: true
    validates :floor_aspect, numericality: { in: 0.4..2.5 }

    def self.set_nickname!(id, nickname)
      find_or_initialize_by(id:).update!(nickname: nickname.to_s.strip.presence)
    end

    def self.set_hidden!(id, hidden)
      find_or_initialize_by(id:).update!(hidden: ActiveModel::Type::Boolean.new.cast(hidden))
    end

    # Replace the dashboard order with the given group ids, first to last.
    # Rooms left out keep their row (and any other settings) but lose their position.
    def self.set_order!(group_ids)
      transaction do
        where.not(id: group_ids).update_all(position: nil)
        group_ids.each_with_index { |id, i| find_or_initialize_by(id:).update!(position: i) }
      end
    end
  end
end
