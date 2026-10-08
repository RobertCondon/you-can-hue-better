class RoomNamesController < ApplicationController
  NAME_FIELDS = %i[name nickname].freeze

  def update
    group = Hue::Group.find(params[:room_id])
    fields = params.require(:room).permit(*NAME_FIELDS)
    if fields.key?(:name)
      BridgeRename.new(group, activity_kind: group.kind).rename_to(fields[:name]) { |name| Hue.client.groups_of_type(group.kind).rename(group.id, name) }
    end
    HueExtensions::Group.set_nickname!(group.id, fields[:nickname]) if fields.key?(:nickname)
    render_renamed(House.load(refresh: false).room(group.id))
  end

  private

  def render_renamed(room)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [ turbo_stream.replace(HouseBroadcast::Targets.room_head(room), partial: "rooms/head", locals: { room: }),
                               turbo_stream.update(HouseBroadcast::Targets::EDITOR_ERROR, "") ]
      end
      format.html { redirect_to root_path }
    end
  end
end
