module Hue
  class Mirror
    class Changes
      attr_reader :light_ids, :group_ids, :scene_ids, :presses

      def initialize
        @light_ids = []
        @group_ids = []
        @scene_ids = []
        @presses = []
        @full_sync_needed = false
      end

      def lights_changed(*changed_light_ids) = @light_ids.concat(changed_light_ids.flatten)
      def group_changed(group_id) = @group_ids << group_id
      def scene_changed(scene_id) = @scene_ids << scene_id
      def press_recorded(control_event) = @presses << control_event
      def full_sync_needed! = @full_sync_needed = true

      def full_sync_needed? = @full_sync_needed
      def house_changed? = light_ids.any? || group_ids.any? || presses.any?
      def any? = house_changed? || scene_ids.any? || full_sync_needed?
    end
  end
end
