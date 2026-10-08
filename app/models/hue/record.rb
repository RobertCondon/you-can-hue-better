module Hue
  # Base for the bridge-mirror tables. All of them are prefixed hue_ and keyed by Hue UUIDs.
  class Record < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = "hue_"
  end
end
