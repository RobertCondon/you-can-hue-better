class UndosController < ApplicationController
  include HouseSectionStreams

  def create
    undo_action = UndoAction.fresh.find(params[:id])
    HouseCommands::UndoReplay.new(undo_action).run
    wait_for_bridge_to_settle
    render_house_sections(toast: done_toast(t(".undone", description: undo_action.description)))
  end
end
