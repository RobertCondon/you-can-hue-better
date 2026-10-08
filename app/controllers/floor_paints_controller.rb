# Paint mode's Apply: one batched send of a colour or white per light, with Undo.
class FloorPaintsController < ApplicationController
  def create
    strokes = Array(JSON.parse(params.require(:strokes))).map { |s| s.transform_keys(&:to_s) }
    ids = strokes.map { _1["light_id"] }.uniq
    lights = Hue::Light.where(id: ids).index_by(&:id)
    raise Hue::Error, "Nothing to paint" if lights.empty?

    undo = UndoAction.capture("Painted #{lights.size} #{"light".pluralize(lights.size)}", lights.keys)
    unreachable = false
    Activity.record(target_kind: "floor", target_id: "paint", target_name: "Paint", action: "paint #{lights.size}", payload: strokes) do
      strokes.each do |s|
        light = lights[s["light_id"]] or next
        response = Hue.client.set_light(light.id, command_for(s))
        unreachable ||= response["unreachable"]
      end
      { "unreachable" => unreachable }
    end
    settle
    HouseBroadcast.changes(Hue::Mirror.apply(lights.keys.map { Hue.client.light(_1) }))

    house = House.load(refresh: false)
    spots = Floor.live(house).spots.index_by { _1.light.id }
    streams = lights.keys.filter_map { |id| spots[id] && turbo_stream.replace("floor_light_#{id}", partial: "floors/light", locals: { spot: spots[id] }) }
    streams << turbo_stream.update("house_summary", partial: "dashboard/summary", locals: { house: })
    streams << (unreachable ? flash_stream(unreachable_message("A painted light")) : undo_stream(undo))
    render turbo_stream: streams
  end

  private

  def command_for(stroke)
    if stroke["mirek"].present?
      { on: { on: true }, color_temperature: { mirek: stroke["mirek"].to_i.clamp(153, 500) } }
    else
      { on: { on: true }, color: { xy: Hue::Color.hex_to_xy(stroke["hex"]) } }
    end
  end
end
