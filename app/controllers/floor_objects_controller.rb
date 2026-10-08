class FloorObjectsController < ApplicationController
  PLACEMENT_FIELDS = %i[x y w h rotation label].freeze

  rescue_from FloorObject::UnknownKind, with: -> { head :unprocessable_entity }

  def create
    floor_object = FloorObjects::Creation.call(group_id: Floor.home.id, kind: params[:kind].to_s)
    render partial: "floors/object", locals: { object: floor_object, editable: true }, layout: false, status: :created
  end

  def update
    FloorObjects::Placement.new(FloorObject.find(params[:id])).apply(params.permit(*PLACEMENT_FIELDS).to_h.symbolize_keys)
    head :no_content
  end

  def destroy
    FloorObject.find(params[:id]).destroy!
    head :no_content
  end
end
