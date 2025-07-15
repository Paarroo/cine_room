Rails.application.routes.draw do
  devise_for :users

  root 'pages#home'


  get '/contact', to: 'pages#contact', as: :contact
  get '/legal',   to: 'pages#legal',   as: :legal
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms',   to: 'pages#terms',   as: :terms
  
  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'

  resources :movies do
    resources :reviews, except: [ :index ]
  end

  resources :events do
    resources :participations, only: [:new, :create, :destroy ]
  end

  resources :creators
  resources :participations, only: [ :index, :show ]
  resources :reviews, only: [ :index, :show ]

  get "up" => "rails/health#show", as: :rails_health_check
end
