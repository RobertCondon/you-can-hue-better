class RoomsController < ApiController
  include HueCalls

  ROOM_FIELDS = %i[on brightness].freeze

  def update
    async_hue_call { room_command(Hue::Group.find(params[:id]), params.require(:room).permit(*ROOM_FIELDS)) }
  end

  def order
    arrangeable_ids = Hue::Group.where(kind: House::Loader::ROOM_KINDS).pluck(:id)
    HueExtensions::Group.set_order!(Array(params[:ids]).map(&:to_s) & arrangeable_ids)
    head :no_content
  end

  private

  def room_command(group, fields)
    return HouseCommands::RoomBrightness.new(group, fields[:brightness]) if fields[:brightness].present?

    HouseCommands::RoomSwitch.new(group, on: ActiveModel::Type::Boolean.new.cast(fields[:on]))
  end
end
