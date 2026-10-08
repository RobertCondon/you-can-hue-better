# Puts back what a room or scene action replaced.
class UndosController < RoomsController
  def create
    undo = UndoAction.fresh.find(params[:id])
    ActivityRecorder.record(target_kind: "undo", target_id: undo.id.to_s, target_name: undo.description, action: "undo #{undo.light_count} lights") do
      Undo::Restore.new(undo).run
    end
    undo.destroy
    settle
    render_rooms(notice: nil, done: "Undone: #{undo.description}")
  end
end
