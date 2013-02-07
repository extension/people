# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Webmail::ExamplesController < ApplicationController

  def signup
    mail = AccountMailer.signup(person: Person.find(1), cache_email: false)
    return render_mail(mail)
  end

  private
  
  def render_mail(mail)
    # send it through the inline style processing
    inlined_content = InlineStyle.process(mail.body.to_s,ignore_linked_stylesheets: true)
    render(:text => inlined_content, :layout => false)
  end

end