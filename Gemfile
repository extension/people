source 'https://rubygems.org'
source 'http://systems.extension.org/rubygems/'

gem 'rails', '3.2.13'

# all things xml
gem 'nokogiri', '1.5.10'

# data
gem 'mysql2'

# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  # files for bootstrap-in-asset-pipeline integration
  gem 'anjlab-bootstrap-rails', '>= 2.0', :require => 'bootstrap-rails'
  gem 'font-awesome-sass-rails'
  gem 'jquery-ui-rails'
  gem 'extension-html5shiv-rails', :require => 'html5shiv-rails'
  gem "select2-rails"
end

# legacy data support
gem 'safe_attributes'

# mobile device detection
gem 'mobile-fu'

# server settings
gem "rails_config"

# jquery magick
gem 'jquery-rails'

# pagination
gem 'kaminari'

# Deploy with Capistrano
gem 'capistrano'
gem 'capatross'

# background jobs
gem 'sidekiq'

# command line tools
gem 'thor'

# To use Jbuilder templates for JSON
gem 'jbuilder'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# exception handling
gem 'airbrake'

# caching
gem 'redis-rails'

# forms
gem 'simple_form'

# openid
gem "ruby-openid", :require => 'openid'

# rest posts
gem 'rest-client'

# validation helpers
# uses the Mail gem to validate email: https://github.com/hallelujah/valid_email
gem 'valid_email'

# used to post-process mail to convert styles to inline
gem "csspool"
gem "inline-style", "0.5.2ex"

# tokens and such
gem 'hashids'

# html scrubbing
gem "loofah"

# useragent analysis
gem 'useragent'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'


# google analytics retrieval
gem "garb" # garb for now until it breaks 

# breadcrumbs
gem "breadcrumbs_on_rails"

# php db munging
gem "php_serialize"

group :development do
  # require the powder gem
  gem 'powder'
  gem 'net-http-spy'
  gem 'pry'

  # footnotes
  #gem 'rails-footnotes', '>= 3.7.5.rc4'
  gem 'quiet_assets'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
end