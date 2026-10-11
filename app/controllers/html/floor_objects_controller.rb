module Html
  class FloorObjectsController < ApplicationController
    def show
      render partial: "floors/item", locals: { item: Floor::Item.find(params[:id]), editable: true }, layout: false
    end
  end
end
