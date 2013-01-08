# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

People::Application.routes.draw do
  root :to => 'home#index'

  resources :accounts, only: [:create]

  # named routes for special accounts paths
  match "signin", to: "accounts#signin", via: [:get,:post], :as => 'signin'
  match "signout", to: "accounts#signout", via: [:get], :as => 'signout'
  match "signup", to: "accounts#signup", via: [:get,:post], :as => 'signup'

  resources :communities do 
    collection do
      get :browse
      get :newest
    end

    member do
      get :connections
      get :invitations
    end

  end

  resources :colleagues, only: [:index, :show]


  match "account/reset_password" => "account#reset_password", :via => [:get, :post], :as => 'reset_password'
  match "account/confirm" => "account#confirm_email", :via => [:get, :post], :as => 'confirm'

  match "debug/session_information", to: "debug#session_information"

end
