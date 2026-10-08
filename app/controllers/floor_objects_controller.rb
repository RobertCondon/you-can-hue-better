class FloorObjectsController < ApplicationController
  PLACEMENT_FIELDS = %i[x y w h rotation label].freeze

  rescue_from Floor::Item::UnknownKind, with: -> { head :unprocessable_entity }

  def create
    item = Floor::Item.create_centred!(group_id: Floor.home.id, kind: params[:kind].to_s)
    render partial: "floors/item", locals: { item:, editable: true }, layout: false, status: :created
  end

  def update
    Floor::Item.find(params[:id]).place!(params.permit(*PLACEMENT_FIELDS).to_h.symbolize_keys)
    head :no_content
  end

  def destroy
    Floor::Item.find(params[:id]).destroy!
    head :no_content
  end
end
