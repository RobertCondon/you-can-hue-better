module Hue
  class Record < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = "hue_"
  end
end
