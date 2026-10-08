class BridgeRename
  ACTION_PREFIX = "rename to"

  def initialize(record, activity_kind:)
    @record = record
    @activity_kind = activity_kind
  end

  def rename_to(new_name, &send_to_bridge)
    new_name = new_name.to_s.strip
    return if new_name == @record.name

    ActivityRecorder.record(target_kind: @activity_kind, target_id: @record.id, target_name: @record.name,
                            action: "#{ACTION_PREFIX} #{new_name}", payload: { name: new_name }) { send_to_bridge.call(new_name) }
    @record.update!(name: new_name)
  end
end
