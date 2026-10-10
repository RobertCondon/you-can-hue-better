module HouseCommands
  class Command
    NO_LIGHTS = [].freeze

    def self.call(...) = new(...).call_now

    def call_now
      check_request!
      claim = Hue::Locks.claim(light_ids) or return busy
      result = ActivityRecorder.record(**activity) { send_to_bridge }
      HouseBroadcast.changes(catch_up_mirror)
      result
    ensure
      Hue::Locks.release(claim)
    end

    def call_later(tab: nil)
      check_request!
      raise NotInstant, self.class.name if light_ids.empty?

      claim = Hue::Locks.claim(light_ids) or return busy
      hand_off(claim, ActivityRecorder.pending(**activity), tab)
    rescue StandardError
      Hue::Locks.release(claim)
      raise
    end

    def deliver = send_to_bridge

    def catch_up = catch_up_mirror

    def check_request! = nil

    def light_ids = NO_LIGHTS

    def kind = self.class.name.demodulize.underscore.to_sym

    def target_name = activity[:target_name]

    def unreachable_description = target_name

    private

    def hand_off(claim, pending_activity, tab)
      Dispatch.later(claim, kind) { Settlement.new(command: self, activity: pending_activity, tab:).settle }
      Accepted.new(light_ids:, check_in_milliseconds: Hue::CallTimings.p95_milliseconds(kind))
    end

    def busy = Busy.new(light_ids:, target_name:)

    def catch_up_mirror
      Hue.wait_for_bridge
      Hue::Mirror.refresh
    end

    def read_back_lights(light_ids) = Hue::Mirror.apply(light_ids.map { |light_id| Hue.client.lights.find(light_id) })
  end
end
