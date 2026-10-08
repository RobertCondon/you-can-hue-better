Rails.application.routes.draw do
  root "dashboard#show"
  get "dev" => "dashboard#dev"

  resources :lights, only: :update do
    get :panel, on: :member
    get :pin, on: :member
    resource :names, only: :update, controller: "light_names"
  end
  resources :rooms,  only: :update do
    patch :order, on: :collection
    resource :names, only: :update, controller: "room_names"
  end
  resource :floor, only: [ :show, :update ] do
    resources :objects, only: :create, controller: "floor_objects"
    resources :nets, only: :create, controller: "floor_nets"
    resource :paint, only: :create, controller: "floor_paints"
  end
  resources :floor_objects, only: [ :update, :destroy ]
  resources :floor_nets, only: [ :update, :destroy ]
  post "undos/:id" => "undos#create", as: :undo
  resource :setup, only: [ :show, :create ], controller: "setup"
  patch "visibility/lights/:id" => "visibility#light", as: :light_visibility
  patch "visibility/rooms/:id"  => "visibility#room",  as: :room_visibility
  resources :scenes, only: [ :index, :show ] do
    post :activate, on: :member
    post :play, on: :member
    get :floor_state, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
