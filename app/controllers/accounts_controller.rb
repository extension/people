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

  # def create
  #   render(template: 'debug/dump_params')
    
  #   if(!params[:invite].nil?)
  #     @invitation = Invitation.find_by_token(params[:invite])
  #   end
    
  #   # search for an existing account.  doing this here instead
  #   # of validations because of historical presence of 'PublicUser'
  #   # accounts - this will be removed when People is separated
  #   if(params[:user] and params[:user][:email])
  #     checkemail = params[:user][:email]
  #     if(account = Account.find_by_email(checkemail))
  #       # has existing user account
  #       failuremsg = "Your email address has already been registered with us.  If you've forgotten your password for that account, please <a href='#{url_for(:controller => 'people/account', :action => :new_password)}'>request a new password</a>"
  #       flash.now[:failure] = failuremsg
  #       @user = User.new(params[:user])          
  #       @locations = Location.displaylist
  #       if(!(@user.location.nil?))  
  #         @countylist = @user.location.counties
  #         @institutionlist = @user.location.communities.institutions.find(:all, :order => 'name')
  #       end
  #       return render(:action => "new")
  #     else
  #       @user = User.new(params[:user])
  #     end
  #   end

  #   # institution?
  #   if(!params[:primary_institution_id].nil? and params[:primary_institution_id] != 0)
  #     @user.additionaldata = {} if @user.additionaldata.nil?
  #     @user.additionaldata.merge!({:signup_institution_id => params[:primary_institution_id]})
  #   end
    
  #   # affiliation/involvement?
  #   if(!params[:signup_affiliation].blank?)
  #     @user.additionaldata = {} if @user.additionaldata.nil?
  #     @user.additionaldata.merge!({:signup_affiliation => Hpricot(params[:signup_affiliation].sanitize).to_html})
  #   else
  #     flash.now[:failure] = "Please let us know how you are involved with Cooperative Extension"
  #     @locations = Location.displaylist
  #     return render(:action => "new")
  #   end
        
  #   # STATUS_SIGNUP
  #   @user.account_status = User::STATUS_SIGNUP
    
  #   # last login at == now
  #   @user.last_login_at = Time.zone.now
    
  #   begin
  #     didsave = @user.save
  #   rescue ActiveRecord::StatementInvalid => e
  #     if(!(e.to_s =~ /duplicate/i))
  #       raise
  #     end
  #   end
    
  #   if(!didsave)        
  #     if(!@user.errors.on(:email).nil? and @user.errors.on(:email) == 'has already been taken')
  #       failuremsg = "Your email address has already been registered with us.  If you've forgotten your password for that account, please <a href='#{url_for(:controller => 'people/account', :action => :new_password)}'>request a new password</a>"
  #       flash.now[:failure] = failuremsg
  #     elsif(!@user.errors.empty?)
  #       failuremsg = "<h3>There were errors that prevented signup</h3>"
  #       failuremsg += "<ul>"
  #       @user.errors.each { |value,msg|
  #         if (value == 'login')
  #           failuremsg += "<li>That eXtensionID #{msg}</li>"
  #         else
  #           failuremsg += "<li>#{value} - #{msg}</li>"
  #         end
  #       }
  #       failuremsg += "</ul>"          
  #       flash.now[:failurelist] = failuremsg
  #     end
  #     @locations = Location.displaylist
  #     if(!(@user.location.nil?))  
  #       @countylist = @user.location.counties
  #       @institutionlist = @user.location.communities.institutions.find(:all, :order => 'name')
  #     end
      
  #     render(:action => "new")
  #   else        
  #     # automatically log them in
  #     @currentuser = User.find_by_id(@user.id)
  #     session[:userid] = @currentuser.id
  #     session[:account_id] = @currentuser.id
  #     signupdata = {}     
  #     if(@invitation)
  #       signupdata.merge!({:invitation => @invitation})
  #     end
  #     UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "initialsignup")
  #     @currentuser.send_signup_confirmation(signupdata)
  #     return redirect_to(:action => :confirmationsent)
  #   end
  # end


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