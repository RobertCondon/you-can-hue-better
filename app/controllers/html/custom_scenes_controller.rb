module Html
  class CustomScenesController < ApplicationController
    def new
      @room = House.load(refresh: false).room(params.require(:group_id)) or raise ActiveRecord::RecordNotFound
      render layout: false
    end

    def edit
      @scene = CustomScene.find(params[:id])
      render layout: false
    end
  end
end
