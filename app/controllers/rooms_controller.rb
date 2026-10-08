class RoomsController < ApplicationController
  include HouseSectionStreams

  def update
    group = Hue::Group.find(params[:id])
    outcome = HouseCommands::RoomSwitch.new(group, on: ActiveModel::Type::Boolean.new.cast(params.require(:room)[:on])).run
    wait_for_bridge_to_settle
    render_house_sections(toast: outcome_toast(outcome, t(".a_light_in", room: group.name)))
  end

  def order
    arrangeable_ids = Hue::Group.where(kind: House::Loader::ROOM_KINDS).pluck(:id)
    HueExtensions::Group.set_order!(Array(params[:ids]).map(&:to_s) & arrangeable_ids)
    head :no_content
  end
end
