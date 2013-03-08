# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

# see config/initializers/add_named_route.rb for simple_named_route

People::Application.routes.draw do
  root :to => 'home#index'

  controller :accounts do
    # non accounts/blah paths
    match "signin", action: "signin", via: [:get,:post]
    match "signout", action: "signout", via: [:get]
    match "signup", action: "signup", via: [:get,:post]
    match "cs/:token", action: "confirm_signup", via: [:get,:post], as: "confirm_signup"
    # everything else
    simple_named_route 'create', via: [:post]
    simple_named_route 'send_confirmation'
    simple_named_route 'reset_password'
    simple_named_route 'missing_token'
    simple_named_route 'review'
  end    

  resources :people, only: [:index, :show, :edit, :update]

  resources :communities do 
    collection do
      get :newest
    end

    member do
      get :connections
      get :invitations
    end
  end

  # json data endpoints
  controller :locations do
    simple_named_route 'counties', via: [:post]
    simple_named_route 'institutions', via: [:post]
  end

  controller :debug do
    simple_named_route 'session_information', via: [:get,:post]
  end

  controller :home do
    match "help", action: 'help', via: [:get,:post]
  end

  controller :webmail do
    match "/webmail/:mailer_cache_id/logo" => "webmail#logo", :as => 'webmail_logo'
    match "/webmail/view/:hashvalue" => "webmail#view", :as => 'webmail_view'
  end


  # email example routing
  match "/email_examples/:action", to: "email_examples", via: [:get]


end

