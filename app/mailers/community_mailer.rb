# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CommunityMailer < BaseMailer
  
  def join(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has joined the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
   
    if(!@recipient.email.blank?)
      return_email = mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end
    
    return_email  
  end

  def pending
  end

  def leave(options = {})
    @community = options[:community]
    @person = options[:person]
    @recipient = options[:recipient]
    @subject = "eXtension: A colleague has left the #{@community.name} community"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]

    if(!@recipient.email.blank?)
      return_email = mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end
    
    return_email      
  end

  def not_pending
  end

end
