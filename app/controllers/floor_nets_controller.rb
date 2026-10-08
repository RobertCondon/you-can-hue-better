class FloorNetsController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  def create
    render json: FloorNets::Drawing.create!(net_attributes), status: :created
  end

  def update
    net = FloorNet.find(params[:id])
    net.update!(net_attributes)
    render json: net
  end

  def destroy
    FloorNet.find(params[:id]).destroy!
    head :no_content
  end

  private

  def net_attributes
    attributes = {}
    attributes[:points] = FloorNets::PointsParam.parse(params[:points]) if params.key?(:points)
    attributes[:group_id] = params[:group_id].presence if params.key?(:group_id)
    attributes[:label] = params[:label].to_s.strip.presence if params.key?(:label)
    attributes
  end

  def render_invalid(error) = render(json: { error: error.message }, status: :unprocessable_entity)
end
