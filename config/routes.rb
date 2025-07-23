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
    root to: 'pages#home', as: :public_home
  end
  root 'pages#home'

  get '/home', to: 'pages#home', as: :public_site

  namespace :admin do
    resources :dashboard, only: [ :index ]

    resources :movies, only: [ :index, :show, :update ]
    resources :events, only: [ :index, :show, :update ]
    resources :users, only: [ :index, :show, :update ]
    resources :participations, only: [ :index, :show, :update ]

    get 'dashboard/refresh', to: 'dashboard#refresh'
    get 'dashboard/quick_stats', to: 'dashboard#quick_stats'
    post 'dashboard/export', to: 'dashboard#export'

    get 'notifications/poll', to: 'notifications#poll'
    get 'reports', to: 'reports#index'
    get 'reports/revenue', to: 'reports#revenue'
    get 'reports/users', to: 'reports#users'
    get 'reports/events', to: 'reports#events'
    get 'system/status', to: 'system#status'
    post 'system/backup', to: 'system#backup'
    post 'system/maintenance', to: 'system#toggle_maintenance'
  end

  namespace :users do
    resources :dashboard, only: [ :show ] do
      get :edit_profile
      patch :update_profile
      member do
        get :upcoming_participations
        get :past_participations
        get :favorite_events
        get :reviews
      end
    end
  end

  get '/contact', to: 'pages#contact', as: :contact
  get '/legal', to: 'pages#legal', as: :legal
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms', to: 'pages#terms', as: :terms
  get '/about', to: 'pages#about', as: :about

  delete '/admin/logout', to: 'application#admin_logout'
  devise_scope :user do
    get '/users/sign_out', to: 'devise/sessions#destroy'
  end

  get "stripe_checkout/success", to: "stripe_checkout#success", as: :stripe_success
  get "stripe_checkout/cancel", to: "stripe_checkout#cancel", as: :stripe_cancel

  resources :movies do
    resources :reviews, except: [ :index ]

    collection do
      get :search
      get :by_genre
      get :featured
    end
  end

  resources :events do
    resources :participations, only: [ :new, :create, :destroy ]

    member do
      get :availability
    end

    collection do
      get :search
      get :filter
      get :calendar
      get :upcoming
      get :past
    end
  end

  resources :creators do
    member do
      get :portfolio
      get :events
    end

    collection do
      get :featured
      get :search
    end
  end

  resources :participations, only: [ :index, :show, :update ] do
    member do
      get :qr_code
      get :ticket
    end

    collection do
      get :upcoming
      get :past
      get :cancelled
    end
  end

  resources :reviews, only: [ :index, :show, :update ] do
    collection do
      get :recent
      get :top_rated
    end
  end

  resources :reservations, only: [ :show, :create, :update ] do
    member do
      get :confirmation
      get :qr_code
    end
  end

  get "/reservation/success", to: "reservations#success", as: :reservation_success

  namespace :api do
    namespace :v1 do
      resources :events, only: [ :index, :show ] do
        get :availability, on: :member
      end

      resources :movies, only: [ :index, :show ] do
        get :search, on: :collection
      end

      resources :users, only: [ :show ] do
        get :dashboard_stats, on: :member
      end
    end
  end

  # WEBHOOKS
  namespace :webhooks do
    post 'stripe', to: 'stripe#handle'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    get "/rails/mailers", to: "rails/mailers#index"
    get "/rails/mailers/*path", to: "rails/mailers#preview"
  end

  # HEALTH & PWA
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
