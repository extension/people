# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AccountMailer < ActionMailer::Base
  helper MailerHelper
  default_url_options[:host] = Settings.urlwriter_host
  default from: Settings.email_from_address
  default bcc: Settings.email_bcc_address
  helper_method :ssl_root_url, :ssl_webmail_logo, :is_demo?
  

  def signup(options = {})
    @person = options[:person]
    @subject = "Please confirm your email address"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@person.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(person: @person, cacheable: @person)
      end
      
      return_email = mail(to: @person.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email
  end

  def welcome(options={})
    @person = options[:person]
    @subject = "Welcome!"
    @will_cache_email = options[:cache_email].nil? ? true : options[:cache_email]
    
    if(!@person.email.blank?)
      if(@will_cache_email)
        # create a cached mail object that can be used for "view this in a browser" within
        # the rendered email.
        @mailer_cache = MailerCache.create(person: @person, cacheable: @person)
      end
      
      return_email = mail(to: @person.email, subject: @subject)
      
      if(@mailer_cache)
        # now that we have the rendered email - update the cached mail object
        @mailer_cache.update_attribute(:markup, return_email.body.to_s)
      end
    end
    
    # the email if we got it
    return_email    
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
