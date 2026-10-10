Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  scope module: :html do
    root "dashboard#show"
    get "dev", to: "dashboard#dev"
    resource :setup, only: [ :show, :create ], controller: "setup"
    resource :floor, only: :show
    resources :scenes, only: [ :index, :show ]
  end
  resources :custom_scenes, only: [ :new, :show, :create, :edit, :update, :destroy ] do
    resource :activation, only: :create, controller: "custom_scene_activations"
  end

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

  resources :locks, only: :index

  resources :scenes, only: [] do
    member do
      post :activate
      post :play
      get :floor_state
    end
  end

  patch "visibility/lights/:id", to: "visibility#light", as: :light_visibility
  patch "visibility/rooms/:id", to: "visibility#room", as: :room_visibility

  patch "floor", to: "floors#update"
  resource :floor, only: [] do
    resources :objects, only: :create, controller: "floor_objects"
    resources :nets, only: :create, controller: "floor_nets"
    resource :paint, only: :create, controller: "floor_paints"
  end
  resources :floor_objects, only: [ :update, :destroy ]
  resources :floor_nets, only: [ :update, :destroy ]
end
