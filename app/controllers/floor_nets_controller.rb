# Room nets and the house outline, drawn and edited in Edit floor.
class FloorNetsController < ApplicationController
  def create
    net = FloorNet.new(points: FloorNet.clean_points(params[:points]), group_id: params[:group_id].presence)
    FloorNet.outlines.delete_all if net.outline?                       # one outline for the house
    net.save!
    render json: net, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    net = FloorNet.find(params[:id])
    attrs = {}
    attrs[:points]   = FloorNet.clean_points(params[:points]) if params.key?(:points)
    attrs[:group_id] = params[:group_id].presence if params.key?(:group_id)
    attrs[:label]    = params[:label].to_s.strip.presence if params.key?(:label)
    net.update!(attrs)
    render json: net
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    FloorNet.find(params[:id]).destroy!
    head :no_content
  end
end
