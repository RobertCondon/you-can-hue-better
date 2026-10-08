module Hue
  class Mirror
    class Sync
      PRUNE_ORDER = [ Scene, Control, Light, Group, Device ].freeze

      def self.call(client = Hue.client) = new(client).call

      def initialize(client)
        @client = client
      end

      def call
        snapshot = BridgeSnapshot.fetch(@client)
        Record.transaction do
          kept_ids = synchronise(snapshot)
          prune(kept_ids)
          ListenerState.current.update!(full_sync_at: Time.current)
        end
        counts
      end

      private

      def synchronise(snapshot)
        kept_ids = {}
        kept_ids[Device] = DeviceStep.new(snapshot).call
        kept_ids[Light] = LightStep.new(snapshot).call
        kept_ids[Group] = GroupStep.new(snapshot).call
        MembershipStep.new(snapshot).call
        kept_ids[Scene] = SceneStep.new(snapshot).call
        kept_ids[Control] = ControlStep.new(snapshot).call
        kept_ids
      end

      def prune(kept_ids)
        PRUNE_ORDER.each { |model| model.where.not(id: kept_ids.fetch(model)).find_each(&:destroy!) }
      end

      def counts
        { devices: Device.count, lights: Light.count, groups: Group.count, scenes: Scene.count, controls: Control.count }
      end
    end
  end
end
