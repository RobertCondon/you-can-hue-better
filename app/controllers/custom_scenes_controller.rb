class CustomScenesController < ApiController
  SCENE_FIELDS = %i[name group_id transition_ms].freeze
  LIGHT_FIELDS = %i[id hue_light_id on brightness color_x color_y mirek _destroy].freeze

  def show
    render json: CustomSceneSerializer.new(CustomScene.includes(:lights).find(params[:id])).serialize
  end

  def create
    scene = CustomScene.create!(scene_params.key?(:lights_attributes) ? scene_params : current_look_params)
    broadcast_room_of(scene)
    render json: CustomSceneSerializer.new(scene).serialize, status: :created
  end

  def update
    scene = CustomScene.find(params[:id])
    scene.update!(scene_params)
    broadcast_room_of(scene)
    render json: CustomSceneSerializer.new(scene.reload).serialize
  end

  def destroy
    scene = CustomScene.find(params[:id])
    scene.destroy!
    broadcast_room_of(scene)
    head :no_content
  end

  private

  def scene_params = params.require(:custom_scene).permit(*SCENE_FIELDS, lights_attributes: LIGHT_FIELDS)

  def current_look_params
    group = Hue::Group.find(scene_params.require(:group_id))
    { **scene_params.to_h.symbolize_keys, lights_attributes: CustomSceneCapture.new(group).lights_attributes }
  end

  def broadcast_room_of(scene)
    room = scene.group_id && House.load(refresh: false).room(scene.group_id)
    HouseBroadcast.send_streams([ HouseBroadcast::Streams.room(room) ]) if room
  end
end
