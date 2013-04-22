# omniauth setup
require 'omniauth-openid'
require 'openid/store/filesystem'
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :open_id,  :store => OpenID::Store::Filesystem.new("#{Rails.root}/tmp/omniauth"), :name => 'extension', :identifier => 'https://people.extension.org'
end

