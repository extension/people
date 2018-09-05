# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

# see config/initializers/add_named_route.rb for simple_named_route
require 'sidekiq/web'
require 'admin_constraint'

People::Application.routes.draw do
  mount Sidekiq::Web => '/queues', :constraints => AdminConstraint.new

  root :to => 'home#index'

  # slackbot
  match '/slackbot/ask' => 'slackbot#ask'


  # straight up redirects
  match "/account/new_password", to: redirect("/accounts/reset_password")
  match "/profile/edit", to: redirect("/people/personal_edit")
  match "invite/:token", to: redirect("/signup/%{token}")
  match "/colleagues", to: redirect("/people")
  match "colleagues/showuser/:idstring", to: redirect("/people/%{idstring}")


  controller :redirection do
    match "profile/me", action: 'my_profile', via: [:get]
    match "accounts/change_password", action: 'password', via: [:get]
    match "sp/:token", action: "reset", via: [:get]
    match "account/set_password", action: "reset", via: [:get]
  end

  controller :accounts do
    # non accounts/blah paths
    match "signup", action: "signup", via: [:get,:post]
    match "signup/:invite", action: "createprofile", via: [:get], as: "invited_signup"
    match "signup/confirm/:token", action: "signup_confirm", via: [:get,:post], as: "confirm_signup"


    match "signin", action: "signin", via: [:get,:post]
    match "signout", action: "signout", via: [:get]
    match "confirm/:token", action: "confirm", via: [:get,:post], as: "confirm_account"
    match "reset/:token", action: "set_password", via: [:get], as: "set_password"

    # everything else
    simple_named_route 'signup_email', via: [:post]
    simple_named_route 'confirmsignup', via: [:get,:post]
    simple_named_route 'createprofile', via: [:get,:post]
    simple_named_route 'create', via: [:post]
    simple_named_route 'send_confirmation'
    simple_named_route 'reset_password', via: [:get,:post]
    simple_named_route 'missing_token'
    simple_named_route 'post_signup'
    simple_named_route 'pending_confirmation'
    simple_named_route 'resend_confirmation'
    simple_named_route 'set_password', via: [:post]
    simple_named_route 'display_eligibility_notice'
    simple_named_route 'tou_notice', via: [:get,:post]
  end

  match "people/invite/:token" =>"people#invite", :via => [:get], as: "invite_people_token"
  resources :people, only: [:index, :show, :edit, :update] do

    member do
      get :activity
      get :create_google_account
      post :create_google_account
      get :retire
      post :retire
      post :restore
      get  :password
      post :password
      get :public_settings
      get :authsummary
      post :setavatar
    end

    collection do
      get :admins
      get :activity
      get :browse
      get :browsefile
      post :filter
      get :filter
      get :invite
      post :invite
      get :invitations
      get :find
      post :find
      post :change_public_setting
      post :change_social_network_publicity
      get :change_social_networks
      get :edit_social_network
      post :edit_social_network
      post :delete_social_network
      get :personal_edit
      get :tou_activity
    end
  end

  resources :communities do
    collection do
      get :activity
      get :newest
      get :find
      post :find
      post :change_notification
      get :contacts
      get :leaders
      get :institutions
    end

    member do
      get :activity
      get :connections
      get :connectionsfile
      get :gallery
      get :invite
      post :invite
      post :join
      post :leave
      post :change_connection
      post :remove_connection
      post :setmasthead
    end
  end

  resources :audits, only: [:index] do
    collection do
      get :admins
      get :aliases
      get :google_apps_email
      get :google_groups
      get :account_status
      get :account_status_list
    end
  end

  resources :numbers, only: [:index] do
    collection do
      get :reminders
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
    simple_named_route 'interests', via: [:get]
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

  # data routes
  controller "data" do
    simple_named_route 'groups', via: [:get]
    simple_named_route 'publicprofile', via: [:get]
    simple_named_route 'communitymembers', via: [:get]
  end

  # email example routing
  match "/email_examples/:action", to: "email_examples", via: [:get]

  # wildcard
  match "debug/:action", to: "debug", :via => [:get]


  # openid related routing
  match 'opie', to: 'opie#index', via: [:get,:post]
  match 'openid/xrds', to: 'opie#idp_xrds'
  match 'opie/delegate/:extensionid', to: 'opie#delegate'
  match 'opie/:action', to: 'opie'

  match '/:extensionid', to: 'opie#person', as: 'public_profile'
  match '/:extensionid/xrds', to: 'opie#person_xrds'


end
