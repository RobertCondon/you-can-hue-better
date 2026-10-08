class RoomsController < ApplicationController
  def update
    room = Hue::Group.find(params[:id])
    on = ActiveModel::Type::Boolean.new.cast(params.require(:room)[:on])
    undo = UndoAction.capture("#{room.display_name} turned #{on ? "on" : "off"}", room.lights.pluck(:id))

    response = Activity.record(target_kind: room.kind, target_id: room.id, target_name: room.name, action: on ? "on" : "off", payload: { on: { on: } }) do
      Hue.client.set_grouped_light(room.grouped_light_id, { on: { on: } })
    end

    settle
    render_rooms(notice: response["unreachable"] ? unreachable_message("A light in #{room.name}") : nil, undo:)
  end

  # Arrange mode sends the full order of room ids, first to last.
  def order
    ids = Array(params[:ids]).map(&:to_s) & Hue::Group.where(kind: %w[room zone]).pluck(:id)
    HueExtensions::Group.set_order!(ids)
    head :no_content
  end

  private

  # Rooms and zones overlap, so every section re-renders after a group change. Scene cards for the
  # scenes involved re-render too; on pages without them the stream is a no-op.
  def render_rooms(notice: nil, scene_ids: [], undo: nil, done: nil)
    HouseBroadcast.changes(Hue::Mirror.refresh)
    house = House.load(refresh: false)
    respond_to do |format|
      format.turbo_stream do
        streams = house.rooms.map { |r| turbo_stream.replace("room_#{r.id}", partial: "rooms/room", locals: { room: r }) }
        Hue::Scene.recallable.where(id: scene_ids).includes(:extension, :group, actions: { light: :extension }).each do |scene|
          streams << turbo_stream.replace("scene_card_#{scene.id}", partial: "scenes/card", locals: { scene: })
        end
        streams << turbo_stream.update("house_summary", partial: "dashboard/summary", locals: { house: })
        streams << (notice ? flash_stream(notice) : undo ? undo_stream(undo) : done ? done_stream(done) : flash_stream(nil))
        render turbo_stream: streams
      end
      format.html { redirect_back_or_to root_path, alert: notice }
    end
  end
end
