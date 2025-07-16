Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :admin_users
  devise_for :users

  root 'pages#home'

  get '/contact', to: 'pages#contact', as: :contact
  get '/legal',   to: 'pages#legal',   as: :legal
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms',   to: 'pages#terms',   as: :terms
  get '/about',   to: 'pages#about',   as: :about

  resources :movies do
    resources :reviews, except: [ :index ]
  end

  resources :events do
    resources :participations, only: [ :new, :create, :destroy ]
  end

  resources :creators
  resources :participations, only: [ :index, :show ]
  resources :reviews, only: [ :index, :show ]

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
