class RoomsController < ApplicationController
  include HouseStreams

  def update
    group = Hue::Group.find(params[:id])
    result = HouseCommands::RoomSwitch.call(group, on: ActiveModel::Type::Boolean.new.cast(params.require(:room)[:on]))
    render_house_sections(toast: result_toast(result, t(".a_light_in", room: group.name)))
  end

  def order
    arrangeable_ids = Hue::Group.where(kind: House::Loader::ROOM_KINDS).pluck(:id)
    HueExtensions::Group.set_order!(Array(params[:ids]).map(&:to_s) & arrangeable_ids)
    head :no_content
  end
end
