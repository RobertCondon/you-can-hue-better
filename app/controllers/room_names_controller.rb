# Name (on the bridge) and nickname (this dashboard only) for a room or zone.
class RoomNamesController < ApplicationController
  def update
    group = Hue::Group.find(params[:room_id])
    p = params.require(:room).permit(:name, :nickname)

    if p.key?(:name) && (name = p[:name].to_s.strip) != group.name
      ActivityRecorder.record(target_kind: group.kind, target_id: group.id, target_name: group.name, action: "rename to #{name}", payload: { name: }) do
        Hue.client.groups_of_type(group.kind).rename(group.id, name)
      end
      group.update!(name:)
    end
    HueExtensions::Group.set_nickname!(group.id, p[:nickname]) if p.key?(:nickname)

    room = House.load(refresh: false).room(group.id)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [ turbo_stream.replace("room_head_#{room.id}", partial: "rooms/head", locals: { room: }),
                               turbo_stream.update("editor_error", "") ]
      end
      format.html { redirect_to root_path }
    end
  end
end
