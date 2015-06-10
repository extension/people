source 'https://rubygems.org'
# deal with this specifically to stop bundler errors
# source 'https://engineering.extension.org/rubygems'

# [core]
gem 'rails', '4.2.1'

# data
gem 'mysql2'

# [core] Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# [core] Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# [core] Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# [core] Use jquery as the JavaScript library
gem 'jquery-rails'
# [core] Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# [core] Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'


# protected attributes until I figure out strong parameters
gem 'protected_attributes'

# add in jquery-ui
gem 'jquery-ui-rails'

# replaces glyphicons
gem 'font-awesome-rails'
# select2 asset packaging - used for tag and filter interfaces
gem "select2-rails"
# files for bootstrap-in-asset-pipeline integration
gem 'bootstrap-sass'
# extension's packaging of html5shiv for the asset pipeline
gem 'extension-html5shiv-rails', :require => 'html5shiv-rails', :source => 'https://engineering.extension.org/rubygems/'

# server settings
gem "rails_config"

# caching
gem 'redis-rails'

# exception handling
gem 'honeybadger'

# terse logging
gem 'lograge'

# background jobs
gem 'sidekiq'
gem 'sinatra'

# pagination
gem 'kaminari'

# command line tools
gem 'thor'

# encrypted passwords
gem 'bcrypt'

# legacy data support
gem 'safe_attributes'

# mobile device detection
gem 'mobile-fu'

# openid
gem "ruby-openid", :require => 'openid'

# rest posts
gem 'rest-client'

# validation helpers
# uses the Mail gem to validate email: https://github.com/hallelujah/valid_email
gem 'valid_email'

# # used to post-process mail to convert styles to inline
# gem "csspool"
# gem "inline-style", "0.5.2ex"

# tokens and such
gem 'hashids'

# html scrubbing
gem "loofah"

# useragent analysis
gem 'useragent'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'

# breadcrumbs
gem "breadcrumbs_on_rails"

# php db munging
gem "php_serialize"

# text cleanup
gem "auto_strip_attributes", "~> 2.0"

# catch rack errors
gem 'rack-robustness'

# google api
gem 'google-api-client'


group :development do
  # # Deploy with Capistrano
  # gem 'capistrano', '~> 2.15.5'
  # gem 'capatross'

  # require the powder gem
  gem 'powder'
  # logging of http requests
  gem 'httplog'
  # awesome consoles
  gem 'pry'

  # shut the asset requests up
  gem 'quiet_assets'

  # much better error pages
  gem 'better_errors'
  gem 'binding_of_caller'
end

# TDB - not sure about these
# group :development, :test do
#   # Call 'byebug' anywhere in the code to stop execution and get a debugger console
#   gem 'byebug'
#
#   # Access an IRB console on exception pages or by using <%= console %> in views
#   gem 'web-console', '~> 2.0'
#
#   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#   gem 'spring'
# end
