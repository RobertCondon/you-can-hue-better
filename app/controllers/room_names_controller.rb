class RoomNamesController < ApiController
  include HueCalls

  NAME_FIELDS = %i[name nickname].freeze

  def update
    group = Hue::Group.find(params[:room_id])
    fields = params.require(:room).permit(*NAME_FIELDS)
    direct_hue_call { HouseCommands::RenameRoom.new(group, fields[:name]) } if fields.key?(:name)
    rename_nickname(group, fields[:nickname]) if fields.key?(:nickname)
    group.reload
    render json: { id: group.id, name: group.name, nickname: HueExtensions::Group.find_by(id: group.id)&.nickname }
  end

  private

  def rename_nickname(group, nickname)
    HueExtensions::Group.set_nickname!(group.id, nickname)
    HouseBroadcast.changes(Hue::Mirror::Changes.new.tap { |changes| changes.group_changed(group.id) })
  end
end
