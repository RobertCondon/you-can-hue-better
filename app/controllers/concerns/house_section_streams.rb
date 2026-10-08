module HouseSectionStreams
  private

  def render_house_sections(toast:, scene_ids: [])
    HouseBroadcast.changes(Hue::Mirror.refresh)
    house = House.load(refresh: false)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ *room_streams(house), *scene_card_streams(scene_ids), summary_stream(house), toast ] }
      format.html { redirect_back_or_to root_path }
    end
  end

  def room_streams(house)
    house.rooms.map { |room| turbo_stream.replace(HouseBroadcast::Targets.room(room), partial: "rooms/room", locals: { room: }) }
  end

  def scene_card_streams(scene_ids)
    Hue::Scene.recallable.where(id: scene_ids).includes(:extension, :group, actions: { light: :extension }).map do |scene|
      turbo_stream.replace(HouseBroadcast::Targets.scene_card(scene), partial: "scenes/card", locals: { scene: })
    end
  end

  def summary_stream(house) = turbo_stream.update(HouseBroadcast::Targets::HOUSE_SUMMARY, partial: "dashboard/summary", locals: { house: })
end
