# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class BaseMailer < ActionMailer::Base
  helper MailerHelper
  default_url_options[:host] = Settings.urlwriter_host
  default from: Settings.email_from_address
  default bcc: Settings.email_bcc_address
  helper_method :ssl_root_url, :ssl_webmail_logo, :is_demo?
  

  def save_sent_email_for_recipient(email,recipient,options = {})
    create_options = {person: recipient, markup: email.body.to_s}
    create_options.merge!({notification: options[:notification]}) if(!options[:notification].blank?)
    SentEmail.create(create_options)
  end

  def ssl_root_url
    if(Settings.app_location != 'localdev')
      root_url(protocol: 'https')
    else
      root_url
    end
  end

  def ssl_webmail_logo
    parameters = {mailer_cache_id: @mailer_cache.id, format: 'png'}
    if(Settings.app_location != 'localdev')
      webmail_logo_url(parameters.merge({protocol: 'https'}))
    else
      webmail_logo_url(parameters)
    end
  end

  def is_demo?
    Settings.app_location != 'production'
  end
end