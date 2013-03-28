# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class AccountsController < ApplicationController
  skip_before_filter :signin_required, except: [:post_signup, :confirm]
  before_filter :signin_optional

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
          Activity.log_local_auth_success(person_id: person.id, authname: params[:email], ip_address: request.remote_ip)
          redirect_back_or_default(root_url)
        rescue AuthenticationError => ae
          flash.now[:failure] = explain_auth_result(ae.error_code.to_i)
          Activity.log_local_auth_failure(person_id: ae.person_id, authname: params[:email], ip_address: request.remote_ip, fail_code: ae.error_code)
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

  def confirm
    if(params[:token].nil?)
      return render(:template => 'account/invalid_token')
    end

    if(!(status_code = current_person.check_token(params[:token])))
      return render(:template => 'account/invalid_token')
    end

    case status_code
    when Person::STATUS_SIGNUP
      confirm_signup
    else
      return render(:template => 'account/invalid_token')
    end
  end    

  def post_signup
  end  



  def confirm_reset
  end

  def confirm_change
  end


  def signup
    reset_session
    if(!request.post?)
      return render(template: 'accounts/eligibility_notice')
    end
      
    if params[:person]
      @person = Person.new(params[:person])
    else
      @person = Person.new
    end

    if(!params[:invite].nil?)
      @invitation = Invitation.find_by_token(params[:invite])
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
    @person = Person.new(params[:person])
 
    if(!params[:invite].nil? and @invitation = Invitation.find_by_token(params[:invite]))
      @person.invitation = @invitation
    end

    # STATUS_SIGNUP
    @person.account_status = Person::STATUS_SIGNUP
    
    # last login at == now
    @person.last_login_at = Time.zone.now
    
    if(@person.save)
      # automatically log them in
      set_current_person(@person)
      current_person.send_signup_confirmation
      Activity.log_activity(person_id: @person.id, activitycode: Activity::SIGNUP, ip_address: request.remote_ip)
      render(template: 'accounts/post_signup')
    else
      render(:action => "signup")
    end
  end

  def review
  end

  def contributor_agreement
  end


  private

  def confirm_signup
    # signup status check
    if(current_person.account_status != Person::STATUS_SIGNUP)
      flash[:notice] = "You have already confirmed your email address"
      return redirect_to(root_url)
    end
    
    current_person.confirm_signup({ip_address: request.remote_ip})
    if(current_person.vouched?)
      return redirect_to(root_url)
    else
      return redirect_to(accounts_review_url)
    end
  end 

  def explain_auth_result(resultcode)
    case resultcode
    when Activity::AUTH_INVALID_ID
      gourl = view_context.link_to('signup for an account',signup_path)
      explanation = "<p>The eXtensionID or email address was not found. Please check that ID/email again, or #{gourl}.</p>"
    when Activity::AUTH_INVALID_PASSWORD
      gourl = view_context.link_to('set a new password',accounts_reset_password_path)
      explanation = "<p>Your eXtension account password is incorrect. Please check your password again.  If you have forgotten your password, you can #{gourl} for your eXtension account.</p>"
    when Activity::AUTH_ACCOUNT_RETIRED
      gourl = view_context.link_to('contact us','#')
      explanation = "<p>Your eXtension account has been retired. Please #{gourl} for more information.</p>"
    when Activity::AUTH_PASSWORD_EXPIRED
      gourl = view_context.link_to('set a new password',accounts_reset_password_path)
      explanation = "<p>Your eXtension password has expired. Please #{gourl} for your eXtension account.</p>"
    else
      explanation = "<p>An unknown error occurred.</p>"
    end
    return explanation.html_safe
  end


end