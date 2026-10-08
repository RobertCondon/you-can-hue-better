# Puts back what a room or scene action replaced.
class UndosController < RoomsController
  def create
    undo = UndoAction.fresh.find(params[:id])
    Activity.record(target_kind: "undo", target_id: undo.id.to_s, target_name: undo.description, action: "undo #{undo.light_count} lights") do
      undo.apply!
      Hue::CommandResult.delivered
    end
    undo.destroy
    settle
    render_rooms(notice: nil, done: "Undone: #{undo.description}")
  end
end
