module Hue
  module Locks
    GUARD = Mutex.new
    HELD = Set.new

    module_function

    def claim(light_ids)
      requested_ids = light_ids.to_set
      GUARD.synchronize do
        next if HELD.intersect?(requested_ids)

        HELD.merge(requested_ids)
        Claim.new(light_ids: requested_ids.to_a.freeze)
      end
    end

    def release(claim)
      return unless claim

      GUARD.synchronize { HELD.subtract(claim.light_ids) }
    end

    def locked?(light_id) = GUARD.synchronize { HELD.include?(light_id) }

    def locked_among(light_ids) = GUARD.synchronize { light_ids.select { |light_id| HELD.include?(light_id) } }
  end
end
