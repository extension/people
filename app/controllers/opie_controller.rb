# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'openid'
require 'openid/consumer/discovery'
require 'openid/extensions/sreg'
require 'openid/store/filesystem'

# extend the data fields for the SReg Request/Response

module OpenID
  module SReg
    DATA_FIELDS.merge!({'extensionid'=>'eXtension ID'})
  end
end

class OpieController < ApplicationController
  layout nil
  include OpenID::Server
  skip_before_filter :verify_authenticity_token
  skip_before_filter :signin_required, :check_hold_status, except: [:decision]
  before_filter :signin_optional

  def delegate
    @person = Person.find_by_idstring(params[:extensionid])
    @openidmeta = openidmeta(@person)
    render(template: 'people/show_public', layout: 'application')
  end

  def index
    # first thing, if we came back here from a login - get the request out of the session
    if(!params[:returnfrom].nil? and params[:returnfrom] == 'login')
      opierequest = session[:last_opierequest]
      if(opierequest.nil?)
        flash[:failure] = "An error occurred during your OpenID login.  Please return to the site you were using and try again."
        return redirect_to(root_url)
      else
        # clear it out of the session
        session[:last_opierequest] = nil
      end
    else
      begin
        opierequest = server.decode_request(params)
      rescue ProtocolError => e
        # invalid openid request, so just display a page with an error message
        render(:text => e.to_s)
        return
      end
    end

    # no openid.mode was given
    unless opierequest
      render(:text => "This is an OpenID server endpoint.")
      return
    end
    #

    server_url = url_for(:action => 'index', :protocol => ((Settings.app_location == 'localdev') ? 'http://': 'https://'))

    if opierequest.kind_of?(CheckIDRequest)
      if is_authorized?(opierequest.id_select,opierequest.identity, opierequest.trust_root)
        if(opierequest.trust_root =~ %r{extension\.org} or opierequest.trust_root =~ %r{\.dev$})
          if(current_person.present_tou_interstitial?)
            session[:last_opierequest] = opierequest
            current_person.set_tou_status
            @tou_url = url_for(:controller => 'opie', :action => 'tou_notice', :protocol => ((Settings.app_location == 'localdev') ? 'http://': 'https://'))
            return render(:template => 'opie/tou_notice', :layout => 'application')
          end
        end

        if(opierequest.id_select)
          if(opierequest.message.is_openid1)
            response = opierequest.answer(true,server_url,current_person.openid_url)
          else
            response = opierequest.answer(true,nil,current_person.openid_url,current_person.openid_url)
          end
        else
          response = opierequest.answer(true)
        end
        # add the sreg response if requested
        add_sreg(opierequest, response)
        Activity.log_remote_auth_success(person_id: current_person.id, site: opierequest.trust_root, ip_address: request.remote_ip)
      elsif opierequest.immediate
        response = opierequest.answer(false, server_url)
      else
        if (checklogin(opierequest.id_select,opierequest.identity,opierequest.trust_root))
          session[:last_opierequest] = opierequest
          @opierequest = opierequest
          @decisionurl = url_for(:controller => 'opie', :action => 'decision', :protocol => ((Settings.app_location == 'localdev') ? 'http://': 'https://'))
          sregrequest = OpenID::SReg::Request.from_openid_request(opierequest)
          if(!sregrequest.nil?)
            askedfields = (sregrequest.required+sregrequest.optional).uniq
            @willprovide = []
            askedfields.each do |field|
              case field
                when 'nickname'
                  @willprovide << "Nickname: #{current_person.first_name}"
                when 'email'
                  @willprovide << "Email: #{current_person.email}"
                when 'fullname'
                  @willprovide << "Fullname: #{current_person.first_name} #{current_person.last_name}"
                when 'extensionid'
                  @willprovide << "eXtensionID: #{current_person.login}"
                else
                  # nada
              end # case
            end # askedfields
          end
          render(:template => 'opie/decide', :layout => 'application')
        else
          session[:last_opierequest] = opierequest
          cookies[:return_to] = url_for(:controller=>"opie", :action =>"index", :returnfrom => 'login')
          return(redirect_to signin_url)
        end
        return
      end

    else
      response = server.handle_request(opierequest)
    end

    render_response(response)
  end

  def person
    @person=Person.find_by_email_or_idstring_or_id(params[:extensionid])
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']

    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic.  Though I expect it will work
    # 99% of the time.
    if (accept and accept.include?('application/xrds+xml') and !@person.nil?)
      return person_xrds
    end

    # content negotiation failed, so just render the user page
    @openidmeta = openidmeta(@person)
    @no_show_navtabs = true
    render(template: 'people/show_public', layout: 'application')
  end

  def person_xrds
    @person= Person.find_by_email_or_idstring_or_id(params[:extensionid])
    proto = ((Settings.app_location == 'localdev') ? 'http://' : 'https://')
    types = [OpenID::OPENID_2_0_TYPE, OpenID::OPENID_1_0_TYPE,OpenID::SREG_URI]
    types_string = ''
    types.each do |type|
      types_string += "<Type>#{type}</Type>\n"
    end

    yadis = <<-END
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="1">
      #{types_string}
      <URI>#{url_for(:controller => 'opie',:protocol => proto)}</URI>
      <LocalID>#{@person.openid_url}</LocalID>
    </Service>
  </XRD>
</xrds:XRDS>
    END

    render(:text => yadis, :content_type => 'application/xrds+xml')
  end

  def decision
    opierequest = session[:last_opierequest]
    if(opierequest.nil?)
      # try to redirect back - because something really weird happened with the session
      if(!request.env["HTTP_REFERER"].nil?)
        return redirect_to(request.env["HTTP_REFERER"])
      else
        # intentionally crash it
        flash[:failure] = "An error occurred during your OpenID login.  Please return to the site you were using and try again."
        return redirect_to(root_url)
      end
    end

    if(params[:commit].blank? or params[:commit] != 'Allow')
      session[:last_opierequest] = nil
      return redirect_to(opierequest.cancel_url)
    else
      if(!site_approved?(opierequest.trust_root))
        current_person.auth_approvals.create(:trust_root => opierequest.trust_root)
      end
      server_url = url_for(:action => 'index', :protocol => 'https://')
      if(opierequest.id_select)
        if(opierequest.message.is_openid1)
          response = opierequest.answer(true,server_url,current_person.openid_url)
        else
          response = opierequest.answer(true,nil,current_person.openid_url,current_person.openid_url)
        end
      else
        response = opierequest.answer(true)
      end
      add_sreg(opierequest, response)
      Activity.log_remote_auth_success(person_id: current_person.id, site: opierequest.trust_root, ip_address: request.remote_ip)
      session[:last_opierequest] = nil
      return render_response(response)
    end
  end

  def tou_notice
    opierequest = session[:last_opierequest]
    if(opierequest.nil? and params[:demoview].blank?)
      # intentionally crash it
      return redirect_to(root_url)
    end

    if(params[:commit].blank?)
      session[:last_opierequest] = nil
      return render(layout: 'application')
    elsif(params[:commit] == 'Remind me next login')
      if([Person::TOU_NOT_PRESENTED, Person::TOU_PRESENTED, Person::TOU_NEXT_LOGIN].include?(current_person.tou_status))
        current_person.set_tou_status
        # keep going
      else
        session[:last_opierequest] = nil
        return render(layout: 'application')
      end
    elsif(params[:commit] == 'I accept the Terms of Use')
      current_person.set_tou_status(Person::TOU_ACCEPTED)
    end

    server_url = url_for(:action => 'index', :protocol => 'https://')
    if(opierequest.id_select)
      if(opierequest.message.is_openid1)
        response = opierequest.answer(true,server_url,current_person.openid_url)
      else
        response = opierequest.answer(true,nil,current_person.openid_url,current_person.openid_url)
      end
    else
      response = opierequest.answer(true)
    end
    add_sreg(opierequest, response)
    Activity.log_remote_auth_success(person_id: current_person.id, site: opierequest.trust_root, ip_address: request.remote_ip)
    session[:last_opierequest] = nil
    return render_response(response)
  end

  def idp_xrds
    return xrds_for_identity_provider
  end

  private

  def checklogin(is_idselect,identity,trust_root)
    if current_person
      if(is_idselect)
        return current_person.activity_allowed?
      else
        if(current_person.openid_url == identity or current_person.openid_url == identity +'/')
          return current_person.activity_allowed?
        else
          flash[:failure] = "The OpenID you used doesn't match the OpenID for your account.  Please use your back button and enter your OpenID: #{current_person.openid_url}"
          return false
        end
      end
    else
      return false
    end
  end

  def server
    if @server.nil?
      endpoint = url_for(:action => 'index', :only_path => false)
      dir = Pathname.new(Rails.root).join('openid').join('store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store,endpoint)
    end
    return @server
  end

  def site_approved?(trust_root)
    if(AuthApproval.find(:first, :conditions => ['person_id = ? and trust_root = ?',current_person.id,trust_root]))
      return true
    elsif(trust_root =~ %r{extension\.org})
      # auto-approve extension.org
      current_person.auth_approvals.create(:trust_root => trust_root)
      return true
    elsif(trust_root =~ %r{lsuagcenter\.com})
      # auto-approve lsuagcenter.com
      current_person.auth_approvals.create(:trust_root => trust_root)
      return true
    else
      return false
    end
  end

  def is_authorized?(is_idselect,identity,trust_root)
    if(checklogin(is_idselect,identity,trust_root))
      return site_approved?(trust_root)
    else
      return false
    end
  end

  def add_sreg(opierequest, response)

    sregrequest = OpenID::SReg::Request.from_openid_request(opierequest)
    return if sregrequest.nil?

    # currently we'll hand out nickname, full name, email, and extensionid
    sreg_response_data = {}
    askedfields = (sregrequest.required+sregrequest.optional).uniq
    askedfields.each do |field|
      case field
        when 'nickname'
          sreg_response_data['nickname'] = current_person.first_name
        when 'email'
          sreg_response_data['email'] = current_person.email
        when 'fullname'
          sreg_response_data['fullname'] = current_person.fullname
        when 'extensionid'
          sreg_response_data['extensionid'] = current_person.idstring
        else
          logger.debug("OpenID Consumer asked for field: #{field} - we don't know how to answer that.")
      end
    end

    sregresponse = OpenID::SReg::Response.extract_response(sregrequest, sreg_response_data)
    response.add_extension(sregresponse)
  end


  def render_response(openidresponse)
    if openidresponse.needs_signing
      signed_response = server.signatory.sign(openidresponse)
    end
    web_response = server.encode_response(openidresponse)

    case web_response.code
    when HTTP_OK
      render :text => web_response.body, :status => 200

    when HTTP_REDIRECT
      redirect_to web_response.headers['location']

    else
      render :text => web_response.body, :status => 400
    end
  end

end
