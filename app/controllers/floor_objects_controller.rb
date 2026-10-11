class FloorObjectsController < ApiController
  PLACEMENT_FIELDS = %i[x y w h rotation label].freeze

  rescue_from Floor::Item::UnknownKind, with: :unprocessable

  def create
    item = Floor::Item.create_centred!(group_id: Floor.home.id, kind: params.require(:kind).to_s)
    render json: FloorItemSerializer.new(item).serialize, status: :created
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
