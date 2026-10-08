class UndosController < ApplicationController
  include HouseStreams

  def create
    undo_action = UndoAction.fresh.find(params[:id])
    HouseCommands::UndoReplay.call(undo_action)
    render_house_sections(toast: done_toast(t(".undone", description: undo_action.description)))
  end
end
