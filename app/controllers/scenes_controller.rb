class ScenesController < ApplicationController
  include HueCalls

  def floor_state
    render json: Floor::ScenePreview.light_states(Hue::Scene.for_cards.find(params[:id]))
  end

  def activate = recall(Hue::Api::SceneRecall::STATIC_LOOK)

  def play = recall(Hue::Api::SceneRecall::PLAY_PALETTE)

  private

  def recall(mode)
    async_hue_call { HouseCommands::SceneRecall.new(Hue::Scene.recallable.find(params[:id]), mode) }
  end
end
