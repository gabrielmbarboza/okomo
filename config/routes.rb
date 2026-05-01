Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      resources :products, only: [:index, :show, :create, :update, :destroy]
      # Future endpoints:
      # resources :orders, only: [:index, :show, :create]
      # resources :payments, only: [:index, :show, :create]
      # resources :shipping, only: [:index, :show, :create]
      # resources :inventory, only: [:index, :show, :create]
    end
  end
end
