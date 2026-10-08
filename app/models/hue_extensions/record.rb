module HueExtensions
  class Record < ApplicationRecord
    MAX_NICKNAME_LENGTH = 40

    self.abstract_class = true
    self.table_name_prefix = "hue_extensions_"

    def self.set_nickname!(id, nickname)
      find_or_initialize_by(id:).update!(nickname: nickname.to_s.strip.presence)
    end

    def self.cast_boolean(value) = ActiveModel::Type::Boolean.new.cast(value)
  end
end
