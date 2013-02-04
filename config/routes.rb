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
    # everything else
    simple_named_route 'create', via: [:post]
    simple_named_route 'send_confirmation'
    simple_named_route 'reset_password'
  end    

  resources :colleagues, only: [:index, :show]


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
  controller :data do
    simple_named_route 'counties_for_location', via: [:post]
    simple_named_route 'institutions_for_location', via: [:post]
  end

  controller :debug do
    simple_named_route 'session_information', via: [:get,:post]
  end

  controller :home do
    match "help", action: 'help', via: [:get,:post]
  end


  controller :profile do
    simple_named_route 'index'
    simple_named_route 'edit', via: [:get,:post]
  end

  controller :webmail do
    match "/webmail/:mailer_cache_id/logo" => "webmail#logo", :as => 'webmail_logo'
    match "/webmail/view/:hashvalue" => "webmail#view", :as => 'webmail_view'
  end


  # webmail example routing
  namespace "webmail" do
    namespace 'examples' do
      match "/:action"
    end
  end


end

