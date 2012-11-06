# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

People::Application.routes.draw do
  root :to => 'home#index'

  # named routes for account actions
  match "signin", to: "account#signin", via: [:get,:post], :as => 'signin'
  match "signout", to: "account#signout", via: [:get], :as => 'signout'

  match "signup", to: "account#signup", via: [:get,:post], :as => 'signup'

  match "account/reset_password" => "account#reset_password", :via => [:get, :post], :as => 'reset_password'
  match "account/confirm" => "account#confirm_email", :via => [:get, :post], :as => 'confirm'


end
