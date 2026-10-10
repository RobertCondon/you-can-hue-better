class CustomScenesController < ApplicationController
  include HouseStreams

  SCENE_FIELDS = %i[name group_id transition_ms].freeze
  LIGHT_FIELDS = %i[id hue_light_id on brightness color_x color_y mirek _destroy].freeze
  ERROR_TARGET = "custom_scene_error"

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  def show
    @scene = CustomScene.includes(:lights).find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: CustomSceneSerializer.new(@scene).serialize }
    end
  end

  def create
    respond_to do |format|
      format.turbo_stream { save_current_look }
      format.any do
        scene = CustomScene.create!(scene_params)
        render json: CustomSceneSerializer.new(scene).serialize, status: :created
      end
    end
  end

  def update
    scene = CustomScene.find(params[:id])
    scene.update!(scene_params)
    respond_to do |format|
      format.turbo_stream { render_room_of(scene) }
      format.any { render json: CustomSceneSerializer.new(scene.reload).serialize }
    end
  end

  def destroy
    scene = CustomScene.find(params[:id])
    scene.destroy!
    respond_to do |format|
      format.turbo_stream { render_room_of(scene) }
      format.any { head :no_content }
    end
  end

  private

  def scene_params = params.require(:custom_scene).permit(*SCENE_FIELDS, lights_attributes: LIGHT_FIELDS)

  def save_current_look
    group = Hue::Group.find(scene_params[:group_id])
    render_room_of(CustomScene.create!(name: scene_params[:name], group:, lights_attributes: CustomSceneCapture.new(group).lights_attributes))
  end

  def render_room_of(scene)
    room = House.load(refresh: false).room(scene.group_id)
    streams = room ? [ HouseBroadcast::Streams.room(room) ] : []
    HouseBroadcast.send_streams(streams)
    render turbo_stream: turbo_streams_for(streams)
  end

  def render_invalid(error)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update(ERROR_TARGET, error.record.errors.full_messages.to_sentence), status: :unprocessable_entity }
      format.any { render json: { error: error.message }, status: :unprocessable_entity }
    end
  end
end
