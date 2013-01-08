# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module AuthLib

  def current_person
    if(!@current_person)
      if(session[:person_id])
        @current_person = Person.find_by_id(session[:person_id])
      end
    end
    @current_person
  end

  private

  def set_current_person(person)
    if(person.blank?)
      @current_person = nil
      reset_session
    else
      @current_person = person
      session[:person_id] = person.id
    end
  end
  
  # TODO: review this, not sure the last_login_at is working 
  def is_authorized?(person)
    if !person
      return false
    elsif person.retired?
      return false
    elsif Settings.reserved_uids.include?(person.id)
      return false
    elsif(!person.last_login_at.blank?)
      if(person.last_login_at < Time.now.utc - 4.days)
        return false
      else
        return true
      end
    elsif(person.created_at < Time.now.utc - 1.days)
      return false
    else
      return true
    end
  end

  def is_sudoer?(person)
    (is_authorized?(person) && Settings.sudoers.include?(person.login))
  end

  def in_purgatory?(person)
    if(!person.vouched?)
      return true
    else # status checks
      case person.account_status
      when Person::STATUS_CONTRIBUTOR
        return false
      when Person::STATUS_PARTICIPANT
        return false
      when Person::STATUS_REVIEWAGREEMENT
        return false
      else
        return true
      end
    end
  end 
    
  def signin_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (is_authorized?(person))
        @current_person = person
      end
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
    access_denied
    return false 
  end
  
  def signin_optional
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (is_authorized?(person))
        @current_person = person
      end
    end
    return true
  end

  def not_in_purgatory_required
    if !in_purgatory?(current_person)
      return true
    else
      clear_location
      access_notice
      return false
    end
  end

  def admin_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (is_authorized?(person) and person.is_admin?)
        @current_person = person
      end
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
    access_denied
    return false 
  end




  def sudo_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (is_authorized?(person) and is_sudoer?(person))
        @current_person = person
      end
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
    access_denied
    return false 
  end



  def access_denied
    redirect_to(signin_url)
  end

  def access_notice
    redirect_to root_url
    #redirect_to people_notice_url
  end  
  

  def openid_xrds_header
    proto = request.ssl? ? 'https://' : 'http://'
    response.headers['X-XRDS-Location'] = url_for(:controller => '/opie', :action => :idp_xrds, :protocol => 'https://')
    xrds_url = url_for(:controller=>'/opie', :action=> 'idp_xrds', :protocol => 'https://')
    return xrds_url
  end

  def openidmeta(openiduser=nil)
    returnstring = '<link rel="openid.server" href="'+AppConfig.openid_endpoint+'" />'
    returnstring += '<link rel="openid2.provider openid.server" href="'+AppConfig.openid_endpoint+'" />'
    if(!openiduser.nil?)
      returnstring += '<link rel="openid2.local_id openid.delegate" href="'+openiduser.openid_url+'" />'
    else
      xrds_url = openid_xrds_header
      returnstring += '<meta http-equiv="X-XRDS-Location" content="'+xrds_url+'" />'+"\n"
    end
    return returnstring
  end

  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    cookies[:return_to] = request.fullpath
  end
  
  def clear_location
    cookies.delete(:return_to)
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if cookies[:return_to].nil?
      redirect_to default
    else
      redirect_to cookies[:return_to]
      cookies.delete(:return_to)
    end
  end

end