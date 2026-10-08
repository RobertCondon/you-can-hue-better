module Hue
  class GroupLight < Record
    belongs_to :group
    belongs_to :light
  end
end
