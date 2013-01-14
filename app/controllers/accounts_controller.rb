# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class AccountsController < ApplicationController
  skip_before_filter :signin_required

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
          person = Person.authenticate(params[:email],params[:password])
          set_current_person(person)
          flash[:success] = "Login successful"
          AuthLog.log_local_success(person_id: person.id, authname: params[:email], ip_address: request.remote_ip)
          redirect_back_or_default(root_url)
        rescue AuthenticationError => ae
          flash.now[:failure] = explain_auth_result(ae.error_code.to_i)
          AuthLog.log_local_failure(person_id: ae.person_id, authname: params[:email], ip_address: request.remote_ip, fail_code: ae.error_code)
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
    reset_session
    if(!request.post?)
      return render(template: 'accounts/eligibility_notice')
    end
        
    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
    end
    
    if params[:person]
      @person = Person.new(params[:person])
    else
      @person = Person.new
    end
    
    @locations = Location.order('entrytype,name')
    if(!(@person.location.nil?))  
      @countylist = @person.location.counties
    end
    
    # html only
    respond_to do |format|
      format.html 
    end
  end

  def create
    
    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
    end

    @person = Person.new(params[:person])
        
    # STATUS_SIGNUP
    @person.account_status = Person::STATUS_SIGNUP
    
    # last login at == now
    @person.last_login_at = Time.zone.now
    
    begin
      didsave = @person.save
    rescue ActiveRecord::StatementInvalid => e
      if(!(e.to_s =~ /duplicate/i))
        raise
      end
    end
    
    if(!didsave)        
      # if(!@person.errors.on(:email).nil? and @person.errors.on(:email) == 'has already been taken')
      #   failuremsg = "Your email address has already been registered with us.  If you've forgotten your password for that account, please <a href='#{url_for(:controller => 'people/account', :action => :new_password)}'>request a new password</a>"
      #   flash.now[:failure] = failuremsg
      # elsif(!@person.errors.empty?)
      #   failuremsg = "<h3>There were errors that prevented signup</h3>"
      #   failuremsg += "<ul>"
      #   @person.errors.each { |value,msg|
      #     if (value == 'login')
      #       failuremsg += "<li>That eXtensionID #{msg}</li>"
      #     else
      #       failuremsg += "<li>#{value} - #{msg}</li>"
      #     end
      #   }
      #   failuremsg += "</ul>"          
      #   flash.now[:failurelist] = failuremsg
      # end
      render(:action => "signup")
    else        
      # automatically log them in
      set_current_person(@person)
      signupdata = {}     
      if(@invitation)
        signupdata.merge!({:invitation => @invitation})
      end
      #UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "initialsignup")
      #current_person.send_signup_confirmation(signupdata)
      #return redirect_to(:action => :confirmationsent)
      render(template: 'debug/dump_params')
    end
  end


  private

  def explain_auth_result(resultcode)
    case resultcode
    when AuthLog::AUTH_INVALID_ID
      gourl = view_context.link_to('signup for an account',signup_path)
      explanation = "<p>The eXtensionID or email address was not found. Please check that ID/email again, or #{gourl}.</p>"
    when AuthLog::AUTH_INVALID_PASSWORD
      gourl = view_context.link_to('set a new password',reset_password_path)
      explanation = "<p>Your eXtension account password is incorrect. Please check your password again.  If you have forgotten your password, you can #{gourl} for your eXtension account.</p>"
    when AuthLog::AUTH_ACCOUNT_RETIRED
      gourl = view_context.link_to('contact us','#')
      explanation = "<p>Your eXtension account has been retired. Please #{gourl} for more information.</p>"
    when AuthLog::AUTH_PASSWORD_EXPIRED
      gourl = view_context.link_to('set a new password',reset_password_path)
      explanation = "<p>Your eXtension password has expired. Please #{gourl} for your eXtension account.</p>"
    else
      explanation = "<p>An unknown error occurred.</p>"
    end
    return explanation.html_safe
  end


end