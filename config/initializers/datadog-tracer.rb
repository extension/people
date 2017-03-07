Rails.configuration.datadog_trace = {
  enabled: (!Settings.app_location.nil? and Settings.app_location == 'production'),
  auto_instrument: (!Settings.app_location.nil?  and Settings.app_location == 'production'),
  auto_instrument_redis: (!Settings.redis_enabled.nil? and Settings.redis_enabled),
  default_service: 'people'
}
