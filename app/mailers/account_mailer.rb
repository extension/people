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
      mail_options = {to: @invitation.email, subject: @subject}
      mail_options[:cc] = @invitation.person.email if !@invitation.person.email.blank?     
      return_email = mail(mail_options)
      save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
    end
    
    return_email    
  end

  def invitation_accepted(options={})
    @invitation = options[:invitation]
    @subject = "eXtension: Your invitation to eXtension has been accepted"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@invitation.person.email.blank?)
      mail_options = {to: @invitation.person.email, subject: @subject}
      mail_options[:cc] = @invitation.colleague.email if (@invitation.colleague && !@invitation.colleague.email.blank?)
      return_email = mail(mail_options)
      save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
    end
    
    return_email    
  end  


end
