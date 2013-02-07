# encoding: utf-8
# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module MailerHelper


  def mailer_logo
    logo_url = @mailer_cache.blank? ? "#{ssl_root_url}/email/logo_small.png" : "#{ssl_webmail_logo}" 
    image_tag(logo_url, alt: 'eXtension People').html_safe
  end
  
end