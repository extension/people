# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EmailExamplesController < ApplicationController

  def index
  end

  def signup
    mail_message = AccountMailer.signup(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end

  def welcome
    mail_message = AccountMailer.welcome(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end

  def confirm
    mail_message = AccountMailer.confirm(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end


  def account_reminder(options={})
    mail_message = AccountMailer.account_reminder(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end

  def password_reset_request(options = {})
    mail_message = AccountMailer.password_reset_request(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end

  def password_reset(options = {})
    mail_message = AccountMailer.password_reset(recipient: Person.system_account, cache_email: false)
    return render_mail(mail_message)
  end

  # def colleague_download_available(options = {})
  #   @browse_filter = options[:browse_filter]
  #   @recipient = options[:recipient]
  #   @subject = "eXtension: Your download is now available"
  #   @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
  #   if(!@recipient.email.blank?)
  #     return_email = create_mail(to: @recipient.email, subject: @subject, send_in_demo: true)
  #     save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
  #   end
    
  #   return_email   
  # end


  # def invitation(options={})
  #   @invitation = options[:invitation]
  #   @subject = "eXtension: You have been invited to join us"
  #   @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
  #   if(!@invitation.email.blank?)
  #     mail_options = {to: @invitation.email, subject: @subject}
  #     mail_options[:cc] = @invitation.person.email if !@invitation.person.email.blank?     
  #     return_email = create_mail(mail_options)
  #     save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
  #   end
    
  #   return_email    
  # end

  # def invitation_accepted(options={})
  #   @invitation = options[:invitation]
  #   @subject = "eXtension: Your invitation to eXtension has been accepted"
  #   @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
  #   if(!@invitation.person.email.blank?)
  #     mail_options = {to: @invitation.person.email, subject: @subject}
  #     mail_options[:cc] = @invitation.colleague.email if (@invitation.colleague && !@invitation.colleague.email.blank?)
  #     return_email = create_mail(mail_options)
  #     save_sent_email_for_recipient(return_email,@invitation.email,options) if @save_sent_email
  #   end
    
  #   return_email    
  # end  

  # def profile_update(options={})
  #   @bycolleague = options[:colleague]
  #   @recipient = options[:recipient]
  #   @what_changed = options[:what_changed]
  #   @subject = "eXtension: Your profile was updated by a colleague"
  #   @save_sent_email = options[:save_sent_email].nil? ? true : options[:save_sent_email]
    
  #   if(!@recipient.email.blank?)
  #     mail_options = {to: @recipient.email, subject: @subject}
  #     mail_options[:cc] = @bycolleague.email if !@bycolleague.email.blank?     
  #     return_email = create_mail(mail_options)
  #     save_sent_email_for_recipient(return_email,@recipient,options) if @save_sent_email
  #   end
    
  #   return_email    
  # end






  
  private
  
  def render_mail(mail_message)
    # is this a multipart? then render the first html part by default, unless the text view is requested
    if(mail_message.multipart?)
      if(params[:view] == 'text')
        @wordwrap = (params[:wordwrap] and params[:wordwrap] == 'no')
        @mailbody = get_first_text_body(mail_message)
        render(:template => 'email_examples/text_email',:layout => false)
      else
        # send it through the inline style processing
        inlined_content = InlineStyle.process(get_first_html_body(mail_message),ignore_linked_stylesheets: true)
        render(:text => inlined_content, :layout => false)
      end
    elsif(mail_message.mime_type == 'text/plain')
      @wordwrap = (params[:wordwrap] and params[:wordwrap] == 'no')
      @mailbody = get_first_text_body(mail_message)
      render(:template => 'email_examples/text_email', :layout => false)      
    elsif(mail_message.mime_type == 'text/html')
      # send it through the inline style processing
      inlined_content = InlineStyle.process(get_first_html_body(mail_message),ignore_linked_stylesheets: true)
      render(:text => inlined_content, :layout => false)      
    else # wtf?
      render(template: 'email_examples/email_error')
    end
  end

  # PLEASE NOTE: - these are built around the assumption of two part emails, one part html and one part text
  # these routines will need to be redesigned if images are ever attached, or there are additional parts
  def get_first_html_body(mail_message)
    if(!mail_message.multipart?)
      if(mail_message.mime_type == 'text/html')
        return mail_message.body.to_s
      else
        return ''
      end
    else
      mail_message.parts.each do |part|
        if(part.mime_type == 'text/html')
          return part
        end
      end
    end
  end

  def get_first_text_body(mail_message)
    if(!mail_message.multipart?)
      if(mail_message.mime_type == 'text/plain')
        return mail_message.body.to_s
      else
        return ''
      end
    else
      mail_message.parts.each do |part|
        if(part.mime_type == 'text/plain')
          return part.body.to_s
        end
      end
    end
  end

end