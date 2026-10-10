class LightNamesController < ApiController
  include HueCalls

  NAME_FIELDS = %i[name nickname].freeze

  def update
    light = Hue::Light.find(params[:light_id])
    fields = params.require(:light).permit(*NAME_FIELDS)
    direct_hue_call { HouseCommands::RenameLight.new(light, fields[:name]) } if fields.key?(:name)
    rename_nickname(light, fields[:nickname]) if fields.key?(:nickname)
    light.reload
    render json: { id: light.id, name: light.name, nickname: HueExtensions::Light.find_by(id: light.id)&.nickname }
  end

  private

  def rename_nickname(light, nickname)
    HueExtensions::Light.set_nickname!(light.id, nickname)
    HouseBroadcast.changes(Hue::Mirror::Changes.new.tap { |changes| changes.lights_changed(light.id) })
  end
end
