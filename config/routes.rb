Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  get 'about', to: 'pages#about'
  get 'contact', to: 'pages#contact'

  resources :movies do
     resources :reviews, except: [:index]
   end

   resources :events do
     resources :participations, only: [:create, :destroy]
   end

   resources :creators
   resources :participations, only: [:index, :show]
   resources :reviews, only: [:index, :show]
 end
  get "up" => "rails/health#show", as: :rails_health_check

end
