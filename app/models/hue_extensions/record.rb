module HueExtensions
  # Base for app-owned tables that extend a Hue mirror row one-to-one, sharing its id.
  # Prefixed hue_extensions_; never written by sync.
  class Record < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = "hue_extensions_"
  end
end
