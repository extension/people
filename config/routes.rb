# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

People::Application.routes.draw do
  root :to => 'home#index'

  resources :accounts, only: [:create] do
    collection do
      get :send_confirmation
      get :confirm
      post :confirm
    end
  end

  # named routes for special accounts paths
  match "signin", to: "accounts#signin", via: [:get,:post], :as => 'signin'
  match "signout", to: "accounts#signout", via: [:get], :as => 'signout'
  match "signup", to: "accounts#signup", via: [:get,:post], :as => 'signup'
  match "account/reset_password" => "account#reset_password", :via => [:get, :post], :as => 'reset_password'


  resources :communities do 
    collection do
      get :newest
    end

    member do
      get :connections
      get :invitations
    end
  end

  resources :colleagues, only: [:index, :show]

  resources :profile

  # json data endpoints
  resources :data, only: [:index] do
    collection do
      post :counties_for_location
      post :institutions_for_location
    end
  end

  # debug paths
  match "debug/session_information", to: "debug#session_information"

  # home paths
  match "help", to: "home#help", via: [:get,:post], :as => 'help'

end
