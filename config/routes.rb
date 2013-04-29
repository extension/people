# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

# see config/initializers/add_named_route.rb for simple_named_route

People::Application.routes.draw do
  ### data subdomain support ###
  constraints(DataSubdomain) do
    match '/' => 'data_home#index', as: 'data_root'

    resources :pages, :only => [:index, :show] do
      member do
        get :traffic_chart
      end
      collection do
        get :panda_impact_summary
        get :totals
        get :aggregate
        post :setdate
        get :comparison_test
        get :graphs
        get :details
        get :overview
        get :publishedcontent
      end
    end

    resources :groups, :only => [:index, :show]

    # data routes
    scope "data" do
      match "/groups", to: "data#groups", :as => 'data_groups'
    end

    resources :contributors, :only => [:show] do
      member do
        get :contributions
        get :metacontributions
      end
    end

    resources :nodes, :only => [:index, :show] do
      collection do
        get :graphs
        get :details
        get :list
      end
    end


    resources :groups, :only => [:index, :show] do
      member do
        get :pagelist
        get :pages
        get :pagetags
      end
    end

    # downloads routing
    resources :downloads, :only => [:index] do 
      collection do
        get 'aae_evaluation'
        get 'aae_questions'
      end

      member do
        get 'getfile'
      end
      
    end

    # authentication
    match '/logout', to:'auth#end', :as => 'logout'
    match '/auth/:provider/callback', to: 'auth#success'

    # home routes
    match '/search', to:'home#search', :as => 'search'

    # experiments named routes
    match '/experiments', to: 'experiments#index', :as => 'experiments'
    # wildcard
    match "/experiments/:action", to: "experiments", :via => [:get,:post]
  end
  
  root :to => 'home#index'

  controller :accounts do
    # non accounts/blah paths
    match "signin", action: "signin", via: [:get,:post]
    match "signout", action: "signout", via: [:get]
    match "signup", action: "signup", via: [:get,:post]
    match "signup/:invite", action: "signup", via: [:get], as: "invited_signup"
    match "confirm/:token", action: "confirm", via: [:get,:post], as: "confirm_account"

    match "sp/:token", action: "set_password", via: [:get], as: "set_password"

    # everything else
    simple_named_route 'create', via: [:post]
    simple_named_route 'send_confirmation'
    simple_named_route 'reset_password', via: [:get,:post]
    simple_named_route 'missing_token'
    simple_named_route 'review'
    simple_named_route 'contributor_agreement', via: [:get,:post]
    simple_named_route 'post_signup'
    simple_named_route 'pending_confirmation'
    simple_named_route 'resend_confirmation'
    simple_named_route 'set_password', via: [:post]
  end    

  resources :people, only: [:index, :show, :edit, :update] do
    member do
      get :activity
      get :retire
      post :retire
      post :restore
      post :vouch
      get  :password
      post :password
      get :public_settings
    end
    
    collection do
      get :activity
      get :browse
      get :browsefile
      post :filter
      get :invite
      post :invite
      get :invitations
      get :find
      post :find
      get :pendingreview
      post :change_public_setting
      post :change_social_network_publicity
      get :change_social_networks
      get :edit_social_network
      post :edit_social_network
      post :delete_social_network
    end
  end

  resources :communities do 
    collection do
      get :activity
      get :newest
      get :find
      post :find
    end

    member do
      get :activity
      get :connections
      get :connectionsfile
      get :invite
      post :invite
      post :join
      post :leave
      post :change_connection
      post :remove_connection
    end
  end

  # json data endpoints
  controller :locations do
    simple_named_route 'counties', via: [:post]
    simple_named_route 'institutions', via: [:post]
  end

  # json data enpoints for tokeninput
  controller :selectdata do
    simple_named_route 'communities', via: [:get]
    simple_named_route 'locations', via: [:get]
    simple_named_route 'positions', via: [:get]
    simple_named_route 'social_networks', via: [:get]
  end  

  controller :debug do
    simple_named_route 'session_information', via: [:get,:post]
  end

  controller :home do
    simple_named_route 'pending'
    match "help", action: 'help', via: [:get,:post]
  end

  controller :webmail do
    match "/webmail/:mailer_cache_id/logo" => "webmail#logo", :as => 'webmail_logo'
    match "/webmail/view/:hashvalue" => "webmail#view", :as => 'webmail_view'
  end


  # email example routing
  match "/email_examples/:action", to: "email_examples", via: [:get]

  # wildcard
  match "debug/:action", to: "debug", :via => [:get]



end

