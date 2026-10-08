Rails.application.routes.draw do
  root "dashboard#show"
  get "dev", to: "dashboard#dev"
  get "up", to: "rails/health#show", as: :rails_health_check
  resource :setup, only: [ :show, :create ], controller: "setup"

  resources :lights, only: :update do
    member do
      get :panel
      get :pin
    end
    resource :names, only: :update, controller: "light_names"
  end

  resources :rooms, only: :update do
    patch :order, on: :collection
    resource :names, only: :update, controller: "room_names"
  end

  resources :scenes, only: [ :index, :show ] do
    member do
      post :activate
      post :play
      get :floor_state
    end
  end

  post "undos/:id", to: "undos#create", as: :undo
  patch "visibility/lights/:id", to: "visibility#light", as: :light_visibility
  patch "visibility/rooms/:id", to: "visibility#room", as: :room_visibility

  resource :floor, only: [ :show, :update ] do
    resources :objects, only: :create, controller: "floor_objects"
    resources :nets, only: :create, controller: "floor_nets"
    resource :paint, only: :create, controller: "floor_paints"
  end
  resources :floor_objects, only: [ :update, :destroy ]
  resources :floor_nets, only: [ :update, :destroy ]
end
