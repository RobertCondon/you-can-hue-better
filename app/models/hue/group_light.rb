module Hue
  class GroupLight < Record
    belongs_to :group
    belongs_to :light
  end
end

# == Schema Information
#
# Table name: hue_group_lights
#
#  id       :integer          not null, primary key
#  group_id :string           not null
#  light_id :string           not null
#
# Indexes
#
#  index_hue_group_lights_on_group_id               (group_id)
#  index_hue_group_lights_on_group_id_and_light_id  (group_id,light_id) UNIQUE
#  index_hue_group_lights_on_light_id               (light_id)
#
# Foreign Keys
#
#  group_id  (group_id => hue_groups.id)
#  light_id  (light_id => hue_lights.id)
#
