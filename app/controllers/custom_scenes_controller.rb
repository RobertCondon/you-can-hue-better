class CustomScenesController < ApplicationController
  SCENE_FIELDS = %i[name group_id transition_ms].freeze
  LIGHT_FIELDS = %i[id hue_light_id on brightness color_x color_y mirek _destroy].freeze

  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  def show
    @scene = CustomScene.includes(:lights).find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: CustomSceneSerializer.new(@scene).serialize }
    end
  end

  def create
    scene = CustomScene.create!(scene_params)
    render json: CustomSceneSerializer.new(scene).serialize, status: :created
  end

  def update
    scene = CustomScene.find(params[:id])
    scene.update!(scene_params)
    render json: CustomSceneSerializer.new(scene.reload).serialize
  end

  private

  def scene_params = params.require(:custom_scene).permit(*SCENE_FIELDS, lights_attributes: LIGHT_FIELDS)

  def render_invalid(error) = render(json: { error: error.message }, status: :unprocessable_entity)
end
