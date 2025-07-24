Rails.application.routes.draw do
  # ActiveAdmin.routes(self)


  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }


  authenticated :user, ->(user) { user.admin? } do
    root to: 'admin/dashboard#index', as: :admin_authenticated_root
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
    root 'dashboard#index'

    resources :dashboard, only: [ :index ] do
      collection do
        get :refresh
        get :quick_stats
        post :export
        post :export_data
        post :backup_database
        # post :toggle_maintenance_mode
      end
    end

    resources :movies, only: [ :index, :show, :update ] do
      member do
        patch :validate_movie
        patch :reject_movie
      end

      collection do
        patch :bulk_validate
        patch :bulk_reject
      end
    end

    resources :events, only: [ :index, :show, :update ] do
      member do
        patch :toggle_status
      end
    end

    resources :users, only: [ :index, :show, :update ] do
      member do
        patch :toggle_role
      end
    end

    resources :participations, only: [ :index, :show, :update ] do
      collection do
        patch :bulk_confirm
        patch :bulk_cancel
      end
    end

    resources :reviews do
          member do
            patch :approve
            patch :reject
            patch :flag
          end

          collection do
            patch :bulk_approve
            patch :bulk_reject
            patch :bulk_delete
            get :analytics
            get :export
            get :stats
            get :quality_report
            get :sentiment_analysis
          end
        end

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
      member do
        get :edit_profile
        patch :update_profile
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
    resources :reviews, except: [ :index ] do
      member do
        patch :approve
        patch :reject
      end
    end

    member do
      patch :validate_movie
      patch :reject_movie
    end

    collection do
      get :search
      get :by_genre
      get :featured
    end
  end

  resources :events do
    resources :participations, only: [ :new, :create, :destroy ] do
      member do
        get :edit
        patch :confirm
        patch :cancel
      end
    end

    member do
      get :availability
      patch :toggle_status
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

  resources :participations, only: [ :index, :show ] do
    member do
      get :qr_code
      get :ticket
      patch :check_in
    end

    collection do
      get :upcoming
      get :past
      get :cancelled
    end
  end

  resources :reviews, only: [ :index, :show ] do
    member do
      patch :like
      patch :unlike
      patch :report
    end

    collection do
      get :recent
      get :top_rated
    end
  end

  resources :reservations, only: [ :show, :create ] do
    member do
      get :confirmation
      get :qr_code
      patch :cancel
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

  namespace :webhooks do
    post 'stripe', to: 'stripe#handle'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    get "/rails/mailers", to: "rails/mailers#index"
    get "/rails/mailers/*path", to: "rails/mailers#preview"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
