class CustomSceneActivationsController < ApplicationController
  include HueCalls

  def create
    async_hue_call { HouseCommands::CustomSceneRecall.new(CustomScene.includes(:lights).find(params[:custom_scene_id])) }
  end
end
