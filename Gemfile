source 'https://rubygems.org'

gem 'rails', '3.2.21'

# all things xml
gem 'nokogiri'

# data
gem 'mysql2'

# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'

# Gems used only for assets and not required
# in production environments by default.
gem 'uglifier', '>= 1.0.3'

group :assets do
  gem 'sass-rails',   '~> 3.2.4'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'jquery-ui-rails'
  # files for bootstrap-in-asset-pipeline integration
  gem 'bootstrap-sass', '~> 3.1.1.1'
  # extension's packaging of html5shiv for the asset pipeline
  gem 'extension-html5shiv-rails', :require => 'html5shiv-rails', :source => 'https://engineering.extension.org/rubygems/'
  # replaces glyphicons
  gem 'font-awesome-rails'
  # select2 asset packaging - used for tag and filter interfaces
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
gem 'capistrano', '~> 2.15.5'
gem 'capatross'

# background jobs
gem 'sidekiq'
gem 'sinatra'

# command line tools
gem 'thor'

# To use Jbuilder templates for JSON
gem 'jbuilder'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# exception handling
gem 'honeybadger'

# caching
gem 'redis-rails'

# openid
gem "ruby-openid", :require => 'openid'

# rest posts
gem 'rest-client'

# validation helpers
# uses the Mail gem to validate email: https://github.com/hallelujah/valid_email
gem 'valid_email'

# used to post-process mail to convert styles to inline
gem "csspool"
gem "inline-style", "0.5.2ex", :source => 'https://engineering.extension.org/rubygems/'

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

# terse logging
gem 'lograge'

# google api
gem 'google-api-client'

# backport of handling json parser errors
gem 'robust_params_parser'

# slack integration
gem "slack-notifier"

# markdown markup
gem 'reverse_markdown'

# image upload and processing
gem 'rmagick'
gem 'carrierwave', "0.10.0ex", :source => 'https://engineering.extension.org/rubygems/'

group :development do
  # require the powder gem
  gem 'powder'
  gem 'httplog'
  gem 'pry'

  # footnotes
  #gem 'rails-footnotes', '>= 3.7.5.rc4'
  gem 'quiet_assets'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
end
