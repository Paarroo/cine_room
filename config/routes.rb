Rails.application.routes.draw do
  # ActiveAdmin.routes(self)

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  root 'pages#home'

  authenticated :user, ->(user) { user.admin? } do
    root to: 'admin/dashboard#index', as: :admin_authenticated_root
  end

  authenticated :user do
    root to: 'pages#home', as: :authenticated_root
  end

  unauthenticated do
    root to: 'pages#home', as: :public_home
  end


  get '/home', to: 'pages#home', as: :public_site

  devise_scope :user do
    get '/users/sign_out', to: 'devise/sessions#destroy'
  end

  delete '/admin/logout', to: 'application#admin_logout'

  get '/contact', to: 'pages#contact', as: :contact
  get '/legal', to: 'pages#legal', as: :legal
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms', to: 'pages#terms', as: :terms
  get '/about', to: 'pages#about', as: :about

  get "/reservation/success", to: "reservations#success", as: :reservation_success

  # Stripe payment processing
  post "payments", to: "payments#create", as: :payments
  get "stripe_checkout/success", to: "stripe_checkout#success", as: :stripe_success
  get "stripe_checkout/cancel", to: "stripe_checkout#cancel", as: :stripe_cancel

  # Stripe webhooks
  namespace :webhooks do
    post 'stripe', to: 'stripe#receive'
  end

  namespace :admin do
    root 'dashboard#index'

    # Main Dashboard
    resources :dashboard, only: [ :index ]

    # Separated stats
    resources :stats, only: [ :index ] do
      collection do
        get :quick
        get :refresh
      end
    end

    # Exports
    resource :exports, only: [ :show ] do
      member do
        get :data
      end
    end

    # Global exports
    resource :movies_exports, only: [ :show ], path: 'movies/export'
    resource :events_exports, only: [ :show ], path: 'events/export'
    resource :participations_exports, only: [ :show ], path: 'participations/export'
    resource :backup_exports, only: [ :show ], path: 'backup/export'
    resource :maintenance_exports, only: [ :show ], path: 'maintenance/export'

    # Backups
    resources :backups, only: [ :create ]

    # Movies RESTful
    resources :movies do
      member do
        patch :validate
        patch :reject
      end

      # Validations bulk nested
      resources :validations, only: [ :create ] do
        collection do
          patch :bulk
        end
      end

      resources :rejections, only: [ :create ] do
        collection do
          patch :bulk
        end
      end

      # Export nested resource
      resource :export, only: [ :show ]
    end

    # Events with status and validation
    resources :events do
      member do
        patch :approve
        patch :reject
      end
      resource :status, only: [ :show, :update ]
      resource :export, only: [ :show ]
    end

    # Users role
    resources :users do
      resource :role, only: [ :show, :update ]
      member do
        patch :reset_password
      end
      resource :export, only: [ :show ]
    end

    # Participations with confirmation
    resources :participations do
      collection do
        patch :bulk_confirm
        patch :bulk_cancel
      end
      
      resources :confirmations, only: [ :create ] do
        collection do
          patch :bulk
        end
      end

      resources :cancellations, only: [ :create ] do
        collection do
          patch :bulk
        end
      end

      # Export nested resource
      resource :export, only: [ :show ]
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

    # Reports
    resources :reports, only: [ :index ] do
      collection do
        get :revenue
        get :users
        get :events
      end
    end

    # System
    namespace :system do
      resources :status, only: [ :show ]
      resources :backups, only: [ :create ]
      resources :maintenance_modes, only: [ :create, :destroy ], path: 'maintenance'
    end
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
        get 'data_export', to: 'dashboard#export', as: :data_export
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :events, only: [ :index, :show ] do
        resources :availabilities, only: [ :show ]
      end

      resources :movies, only: [ :index, :show ] do
        resources :searches, only: [ :index ]
      end

      resources :users, only: [ :show ] do
        resources :dashboard_stats, only: [ :show ]
      end
    end
  end

  resources :movies do
    resources :reviews, except: [ :index ] do
      member do
        patch :approve
        patch :reject
      end
    end

    member do
      patch :validate
      patch :reject
    end

    # Recherches/filters
    resources :searches, only: [ :index ], path: 'search'
    resources :genre_filters, only: [ :index ], path: 'by_genre'
    resources :featured_selections, only: [ :index ], path: 'featured'
  end

  resources :events do
    resources :reviews, only: [ :new, :create, :edit, :update, :destroy ]
    resources :participations, only: [ :new, :create, :destroy ] do
      member do
        get :edit
        patch :confirm
        patch :cancel
      end
    end

    # State action
    resource :status, only: [ :show, :update ]
    resources :availabilities, only: [ :show ]

    resources :searches, only: [ :index ]
    resources :filters, only: [ :index ]
    resources :calendars, only: [ :index ]

    collection do
      get :upcoming
      get :past
    end
  end

  resources :creators do
    resources :portfolios, only: [ :show ]
    resources :creator_events, only: [ :index ], path: 'events'

    resources :featured_selections, only: [ :index ], path: 'featured'
    resources :searches, only: [ :index ]
  end

  resources :participations, only: [ :index, :show ] do
    resources :qr_codes, only: [ :show ]
    resources :tickets, only: [ :show ]
    resources :check_ins, only: [ :create ]

    collection do
      get :upcoming
      get :past
      get :cancelled
    end
  end

  resources :reviews, only: [ :index, :show ] do
    # Interaction actions as nested resources
    resources :likes, only: [ :create, :destroy ]
    resources :reports, only: [ :create ]

    collection do
      get :recent
      get :top_rated
    end
  end

  resources :favorites, only: [ :index, :create, :destroy ]

  resources :reservations, only: [ :show, :create ] do
    resources :confirmations, only: [ :show ]
    resources :qr_codes, only: [ :show ]
    resources :cancellations, only: [ :create ]
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
