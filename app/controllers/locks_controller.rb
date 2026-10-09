class LocksController < ApplicationController
  def index
    render json: { locked: Hue::Locks.locked_among(Array(params[:light_ids]).map(&:to_s)) }
  end
end
