# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AccountMailer < BaseMailer

  def signup(options = {})
    @person = options[:person]
    @subject = "Please confirm your email address"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@person.email.blank?)
      return_email = mail(to: @person.email, subject: @subject)
      save_sent_email_for_person(return_email,@person) if @save_sent_email
    end
    
    return_email   
  end

  def welcome(options={})
    @person = options[:person]
    @subject = "Welcome!"
    @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
    if(!@person.email.blank?)
      return_email = mail(to: @person.email, subject: @subject)
      save_sent_email_for_person(return_email,@person) if @save_sent_email
    end
    
    return_email    
  end

end
