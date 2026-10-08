class LightsController < ApplicationController
  # The expanded, in-depth view of one light, inserted under its tile by the page.
  def panel
    light = House.load(refresh: false).light(params[:id]) or raise ActiveRecord::RecordNotFound
    render partial: "lights/panel", locals: { light: }, layout: false
  end

  # The pinned light: a compact bar for the top of the page with the full panel folded underneath.
  def pin
    light = House.load(refresh: false).light(params[:id]) or raise ActiveRecord::RecordNotFound
    render partial: "lights/pin", locals: { light: }, layout: false
  end

  def update
    light = Hue::Light.find(params[:id])
    body, action = command_for(light)

    response = ActivityRecorder.record(target_kind: "light", target_id: light.id, target_name: light.name, action:, payload: body) do
      Hue.client.lights.update(light.id, body)
    end
    notice = unreachable_message(light.name) if response.unreachable_lights?

    # Catch the mirror up now rather than waiting for the event stream, so the response is current.
    HouseBroadcast.changes(Hue::Mirror.apply([ Hue.client.lights.find(light.id) ]))
    house = House.load(refresh: false)
    light = house.light(light.id)

    respond_to do |format|
      format.turbo_stream do
        streams = house.rooms.select { |r| r.lights.include?(light) }.flat_map do |room|
          [ turbo_stream.replace("light_#{room.id}_#{light.id}", partial: "lights/light", locals: { light:, room: }),
            turbo_stream.replace("room_head_#{room.id}", partial: "rooms/head", locals: { room: }) ]
        end
        streams << turbo_stream.replace("light_panel_#{light.id}", partial: "lights/panel", locals: { light: })
        streams << turbo_stream.replace("light_pin_#{light.id}", partial: "lights/pin", locals: { light: })
        streams << turbo_stream.update("house_summary", partial: "dashboard/summary", locals: { house: })
        streams << flash_stream(notice)
        render turbo_stream: streams
      end
      format.html { redirect_to root_path, alert: notice }
    end
  end

  private

  # Each control in the panel posts just its own field.
  def command_for(light)
    p = params.require(:light).permit(:on, :brightness, :color, :x, :y, :mirek)
    if p[:on].present?
      on = p[:on] == "toggle" ? light.off? : ActiveModel::Type::Boolean.new.cast(p[:on])
      [ { on: { on: } }, on ? "on" : "off" ]
    elsif p[:brightness].present?
      bri = p[:brightness].to_f.clamp(1, 100)
      [ { on: { on: true }, dimming: { brightness: bri } }, "brightness #{bri.round}%" ]
    elsif p[:color].present?
      [ { on: { on: true }, color: { xy: Hue::Color.hex_to_xy(p[:color]) } }, "colour #{p[:color]}" ]
    elsif p[:x].present? && p[:y].present?
      xy = { x: p[:x].to_f.clamp(0, 1).round(4), y: p[:y].to_f.clamp(0, 1).round(4) }
      [ { on: { on: true }, color: { xy: } }, "colour #{Hue::Color.xy_to_hex(xy[:x], xy[:y])}" ]
    elsif p[:mirek].present?
      mirek = p[:mirek].to_i.clamp(153, 500)
      [ { on: { on: true }, color_temperature: { mirek: } }, "white #{(1_000_000 / mirek).round(-2)}K" ]
    else
      raise Hue::Error, "Nothing to change"
    end
  end
end
