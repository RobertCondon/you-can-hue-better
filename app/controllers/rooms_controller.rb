class RoomsController < ApplicationController
  include HueCalls

  def update
    async_hue_call do
      group = Hue::Group.find(params[:id])
      HouseCommands::RoomSwitch.new(group, on: ActiveModel::Type::Boolean.new.cast(params.require(:room)[:on]))
    end
  end

  def order
    arrangeable_ids = Hue::Group.where(kind: House::Loader::ROOM_KINDS).pluck(:id)
    HueExtensions::Group.set_order!(Array(params[:ids]).map(&:to_s) & arrangeable_ids)
    head :no_content
  end
end
