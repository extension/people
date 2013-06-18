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
  
    
  def signin_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (person.signin_allowed?)
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
      if (person.signin_allowed?)
        @current_person = person
      end
    end
    return true
  end

  def check_hold_status
    if current_person.activity_allowed?
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
      if (person.signin_allowed? and person.is_admin?)
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
      if (person.is_sudoer?)
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
    # check for xrds request
    if(request.env['HTTP_ACCEPT'] and request.env['HTTP_ACCEPT'].include?('application/xrds+xml'))
      openid_xrds_header
      return xrds_for_identity_provider
    else
      openid_xrds_header
      return redirect_to(signin_url)
    end
  end

  def access_notice
    redirect_to home_pending_url
  end

  def xrds_for_identity_provider
    proto = ((Settings.app_location == 'localdev') ? 'http://' : 'https://')
    types = [OpenID::OPENID_IDP_2_0_TYPE]
    types_string = ''
    types.each do |type|
      types_string += "<Type>#{type}</Type>\n"
    end

    yadis = <<-END
    <?xml version="1.0" encoding="UTF-8"?>
    <xrds:XRDS
        xmlns:xrds="xri://$xrds"
        xmlns="xri://$xrd*($v*2.0)">
      <XRD>
        <Service priority="1">
          #{types_string}
          <URI>#{url_for(:controller => 'opie',:protocol => proto)}</URI>
        </Service>
      </XRD>
    </xrds:XRDS>
    END

    render(:text => yadis, :content_type => 'application/xrds+xml')    
  end

  def openid_xrds_header
    proto = ((Settings.app_location == 'localdev') ? 'http://' : 'https://')
    response.headers['X-XRDS-Location'] = url_for(:controller => '/opie', :action => :idp_xrds, :protocol => proto)
    xrds_url = url_for(:controller=>'/opie', :action=> 'idp_xrds', :protocol => proto)
    return xrds_url
  end

  def openidmeta(person=nil)
    returnlinks = []
    returnlinks << '<link rel="openid.server" href="'+Settings.openid_endpoint+'" />'
    returnlinks << '<link rel="openid2.provider openid.server" href="'+Settings.openid_endpoint+'" />'
    if(!person.nil?)
      returnlinks << '<link rel="openid2.local_id openid.delegate" href="'+person.openid_url+'" />'
    else
      xrds_url = openid_xrds_header
      returnlinks <<'<meta http-equiv="X-XRDS-Location" content="'+xrds_url+'" />'+"\n"
    end
    return returnlinks.join("\n").html_safe
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