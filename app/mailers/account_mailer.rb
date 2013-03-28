# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AccountMailer < BaseMailer

  def signup(options = {})
    @recipient = options[:recipient]
    @subject = "eXtension: Please confirm your email address"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@recipient.email.blank?)
      return_email = mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end
    
    return_email   
  end

  def welcome(options={})
    @recipient = options[:recipient]
    @subject = "eXtension: Welcome!"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@recipient.email.blank?)
      return_email = mail(to: @recipient.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
    end
    
    return_email    
  end

  def invitation(options={})
    @invitation = options[:invitation]
    @subject = "eXtension: You have been invited to join us"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@invitation.email.blank?)
      return_email = mail(to: @invitation.email, subject: @subject)
      save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
    end
    
    return_email    
  end


end
