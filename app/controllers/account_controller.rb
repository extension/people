# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AccountController < ApplicationController

  def signout
    set_current_person(nil)
    flash[:success] = "You have signed out."
    redirect_to(signin_url)
  end

  def signin
    #  TODO: put openidmeta data in header
    # @openidmeta = openidmeta(@openiduser)

    if request.post?
      if(params[:email].present? and params[:password].present?)
        begin
          set_current_person(Person.authenticate(params[:email],params[:password]))
          flash[:success] = "Login successful"
          #TODO log successful authentication
          redirect_back_or_default(root_url)
        rescue AuthenticationError => errorcode
          flash.now[:failure] = explain_auth_result(errorcode.message.to_i)
          # TODO log failed authentication
        end
      else
        flash.now[:failure]  = '<p>An email address and password is required to sign in.</p>'.html_safe
      end
    else
      if(!current_person.nil?)
        redirect_to(root_url)
      end
    end
  end

  def reset_password
  end

  def confirm_email
  end

  def signup
  end


  private

  def explain_auth_result(resultcode)
    case resultcode
    when Person::AUTH_INVALID_ID
      gourl = view_context.link_to('signup for an account',signup_path)
      explanation = "<p>The eXtensionID or email address was not found. Please check that ID/email again, or #{gourl}.</p>"
    when Person::AUTH_INVALID_PASSWORD
      gourl = view_context.link_to('set a new password',reset_password_path)
      explanation = "<p>Your eXtension account password is incorrect. Please check your password again.  If you have forgotten your password, you can #{gourl} for your eXtension account.</p>"
    when Person::AUTH_ACCOUNT_RETIRED
      gourl = view_context.link_to('contact us','#')
      explanation = "<p>Your eXtension account has been retired. Please #{gourl} for more information.</p>"
    when Person::AUTH_PASSWORD_EXPIRED
      gourl = view_context.link_to('set a new password',reset_password_path)
      explanation = "<p>Your eXtension password has expired. Please #{gourl} for your eXtension account.</p>"
    else
      explanation = "<p>An unknown error occurred.</p>"
    end
    return explanation.html_safe
  end


end