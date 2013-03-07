# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EmailExamplesController < ApplicationController

  def signup
    mail_message = AccountMailer.signup(person: Person.find(1), cache_email: false)
    return render_mail(mail_message)
  end

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