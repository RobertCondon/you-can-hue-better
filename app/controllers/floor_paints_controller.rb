class FloorPaintsController < ApplicationController
  def create
    paint = FloorPaint.new(params.require(:strokes))
    paint.apply!
    settle
    paint.refresh_mirror!
    house = House.load(refresh: false)
    render turbo_stream: [ *painted_lamp_streams(house, paint), summary_stream(house), outcome_stream(paint) ]
  end

  private

  def painted_lamp_streams(house, paint)
    spots = Floor.live(house).spots.index_by { |spot| spot.light.id }
    paint.painted_light_ids.filter_map do |light_id|
      spot = spots[light_id] or next
      turbo_stream.replace(HouseBroadcast::Targets.floor_lamp(spot.light), partial: "floors/light", locals: { spot: })
    end
  end

  def summary_stream(house) = turbo_stream.update(HouseBroadcast::Targets::HOUSE_SUMMARY, partial: "dashboard/summary", locals: { house: })

  def outcome_stream(paint)
    paint.result.unreachable_lights? ? flash_stream(unreachable_message(t(".a_painted_light"))) : undo_stream(paint.undo)
  end
end
