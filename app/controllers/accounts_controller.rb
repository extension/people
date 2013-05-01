# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class AccountsController < ApplicationController
  skip_before_filter :check_hold_status
  skip_before_filter :signin_required, except: [:post_signup, :confirm, :resend_confirmation, :pending_confirmation]
  before_filter :signin_optional

  def signout
    set_current_person(nil)
    flash[:success] = "You have signed out."
    redirect_to(signin_url)
  end

  def signin
    @openidmeta = openidmeta(nil)

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
    if(request.post?)
      if(!params[:email])
        flash.now[:error] = 'You must provide your email address'
      else
        @person = Person.find_by_email(params[:email])
        if(@person.nil?)
          @person = Person.find_by_idstring(params[:email])
        end

        if(@person.nil?)
          flash.now[:warning] = "We are not able to find an account registered with that email address"
        elsif(Person::SYSTEMS_USERS.include?(@person.id))
          flash.now[:warning] = "The password for that account can't be reset"
        elsif(@person.retired?)
          flash.now[:warning] = "Your account has been retired. #{link_to('Contact us for more information.',help_path)}".html_safe
        else
          Activity.log_activity(person_id: @person.id, activitycode: Activity::PASSWORD_RESET_REQUEST, ip_address: request.remote_ip)
          Notification.create(:notification_type => Notification::PASSWORD_RESET_REQUEST, :notifiable => @person)
          return render(template: 'accounts/pending_reset_confirmation')
        end
      end
    end
  end

  def set_password
    #TODO investigate mechanisms to slow this down if we get a lot of requests from the same ip
    if(params[:token].blank?)
      return render(template: 'accounts/invalid_token_set_password')
    end

    if(!(@person = Person.find_by_reset_token(params[:token])))
      return render(template: 'accounts/invalid_token_set_password')
    end

    if(request.post?)
      if(!params[:person])
        @person.errors.add(:base, "Missing parameters".html_safe)
      elsif(!params[:person][:password] or params[:person][:password].length < 8)
        @person.errors.add(:password, "Your new password must be a minimum of 8 characters".html_safe)
      elsif(!params[:person][:password_confirmation] or (params[:person][:password_confirmation] != params[:person][:password]))
        @person.errors.add(:password, "Your password confirmation did not match the new password.".html_safe)        
      else
        @person.password = params[:person][:password]
        if(@person.set_hashed_password(save: true))
          @person.clear_reset_token
          Notification.create(:notification_type => Notification::PASSWORD_RESET, :notifiable => @person)
          Activity.log_activity(person_id: @person.id, 
                                activitycode: Activity::PASSWORD_RESET, 
                                ip_address: request.remote_ip)            
          flash[:notice] = 'Your password has been changed. Please sign-in with your new password.'
          return redirect_to(signin_url)
        end
      end
    end
  end

  def resend_confirmation
    if([Person::STATUS_SIGNUP,Person::STATUS_CONFIRM_EMAIL].include?(current_person.account_status) and !current_person.emailconfirmed?)
      current_person.resend_confirmation
      flash[:notice] = 'Confirmation email resent.'
      return redirect_to(accounts_pending_confirmation_url)
    else
      flash[:notice] = 'No need to resend confirmation, your email address is confirmed.'
      return redirect_to(root_url)     
    end
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
    when Person::STATUS_CONFIRM_EMAIL
      confirm_email
    else
      return render(:template => 'account/invalid_token')
    end
  end    

  def post_signup
  end

  def pending_confirmation
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
    if(request.post?)
      if(current_person.contributor_agreement.nil?)
        if(params[:agreement_agree])
          current_person.contributor_agreement = true
          current_person.contributor_agreement_at = Time.zone.now
          if(current_person.save)
            flash[:success] = 'Thank you for your response'
          end
        elsif(params[:agreement_noagree])
          current_person.contributor_agreement = false
          current_person.contributor_agreement_at = Time.zone.now
          if(current_person.save)
            flash[:success] = 'Thank you for your response'
          end
        end
      end
      return redirect_to(accounts_contributor_agreement_url)
    end 
  end


  private

  def confirm_signup
    # signup status check
    if(current_person.account_status != Person::STATUS_SIGNUP)
      flash[:notice] = "You have already confirmed your email address"
      return redirect_to(root_url)
    end
    
    flash[:notice] = "Thank you for confirming your email address"
    current_person.confirm_signup({ip_address: request.remote_ip})
    if(current_person.vouched?)
      return redirect_to(root_url)
    else
      return redirect_to(accounts_review_url)
    end
  end

  def confirm_email
    if(current_person.account_status != Person::STATUS_CONFIRM_EMAIL and current_person.email_confirmed?)
      flash[:notice] = "You have already confirmed your email address"
      return redirect_to(root_url)
    end
    
    flash[:notice] = "Thank you for confirming your email address"
    current_person.confirm_email({ip_address: request.remote_ip})
    return redirect_to(root_url)
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