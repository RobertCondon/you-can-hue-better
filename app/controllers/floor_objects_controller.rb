# Walls and furniture on the house floor, edited in place from Edit floor.
class FloorObjectsController < ApplicationController
  def create
    object = FloorObject.add!(group_id: Floor.home.id, kind: params[:kind].to_s)
    render partial: "floors/object", locals: { object:, editable: true }, layout: false, status: :created
  rescue ArgumentError
    head :unprocessable_entity
  end

  def update
    FloorObject.find(params[:id]).place!(params.permit(:x, :y, :w, :h, :rotation, :label).to_h.symbolize_keys)
    head :no_content
  end

  def destroy
    FloorObject.find(params[:id]).destroy!
    head :no_content
  end
end
