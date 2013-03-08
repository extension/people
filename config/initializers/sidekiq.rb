sidekiq_redis = { :url => 'redis://localhost:6379/0'}
Sidekiq.configure_server { |config| config.redis = sidekiq_redis }
Sidekiq.configure_client { |config| config.redis = sidekiq_redis }