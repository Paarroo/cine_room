Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  authenticated :user, ->(user) { user.admin? } do
    root to: redirect('/admin'), as: :admin_authenticated_root
  end

  authenticated :user do
    root to: 'pages#home', as: :authenticated_root
  end

  unauthenticated do
    root to: 'pages#home'
  end

  namespace :users do
    resources :dashboard, only: [ :show ] do
      get :edit_profile
      patch :update_profile
      member do
        get :upcoming_participations
        get :past_participations
      end
    end
  end

  get '/contact', to: 'pages#contact', as: :contact
  get '/legal',   to: 'pages#legal',   as: :legal
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms',   to: 'pages#terms',   as: :terms
  get 'about', to: 'pages#about'

  delete '/admin/logout', to: 'application#admin_logout'

  devise_scope :user do
    get '/users/sign_out', to: 'devise/sessions#destroy'
  end

  get "stripe_checkout/success", to: "stripe_checkout#success", as: :stripe_success
  get "stripe_checkout/cancel",  to: "stripe_checkout#cancel",  as: :stripe_cancel

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

  resources :reservations, only: [ :show ]
  get "/reservation/success", to: "reservations#success", as: :reservation_success

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
