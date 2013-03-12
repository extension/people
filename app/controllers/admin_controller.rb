# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class AdminController < ApplicationController
  before_filter :admin_required
  before_filter :sudo_required, :only => [:adminevents,:adminusers, :show_config, :reload_config]
  before_filter :check_purgatory

  
  # -----------------------------------
  # Sudo Actions
  # -----------------------------------
  
  def adminevents
    @admineventslist = AdminEvent.paginate(:all, :order => 'created_at DESC', :page => params[:page])
  end
  
  def adminusers
    labels = Hash.new
    findopts = Hash.new
    labels[:page_title] = "Admin Users"
    findopts[:order] = 'last_name asc'
    findopts[:conditions] = "is_admin = 1"
    userlist(false,'admin_users',labels,findopts)
  end
    
  # -----------------------------------
  # End - Sudo Actions
  # -----------------------------------
  
  def alias_list
    @alias_list = EmailAlias.all(:conditions => "alias_type IN (#{EmailAlias::INDIVIDUAL_ALIAS},#{EmailAlias::SYSTEM_ALIAS},#{EmailAlias::SYSTEM_FORWARD})", :order => 'mail_alias ASC')
  end
  
  def retire
    if not params[:id].nil?
      @showuser = User.find_by_login(params[:id])
      if @showuser
        if request.post?
          if params[:reason].nil? or params[:reason].empty?
            flash.now[:failure] = 'A reason for disabling this eXtensionID is required'      
            @showuser.errors.add("A reason for disabling this eXtensionID is required")
          else
            if(!@showuser.retire(@currentuser,params[:reason]))
              flash.now[:failure] = 'Failed to retire user, reported status may not be correct'      
            end
            @events = UserEvent.find(:all, :order => 'created_at desc', :conditions => ['login = :login or login = :email', { :login => @showuser.login, :email => @showuser.email }])
            render :template => 'people/admin/showuser'
          end
        else
          # show form
        end
      else
        flash.now[:warning] = 'User not found.'      
        render :template => 'people/admin/showuser'
      end
    else
      flash.now[:warning] = 'Missing user.'      
      render :template => 'people/admin/showuser'
    end    
  end
    
  def enable
    if not params[:id].nil?
      @showuser = User.find_by_login(params[:id])
      if @showuser
        if request.post?
          if params[:reason].nil? or params[:reason].empty?
            flash.now[:failure] = 'A reason for enabling this eXtensionID is required'      
            @showuser.errors.add("A reason for enabling this eXtensionID is required")
          else
            if @showuser.enable
              AdminEvent.log_event(@currentuser, AdminEvent::ENABLE_ACCOUNT,{:extensionid => @showuser.login, :reason => params[:reason]})
              UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @showuser,:description => "account enabled by #{@currentuser.login}")
            else
              flash.now[:failure] = 'Failed to enable user, reported status may not be correct'      
            end
            @events = UserEvent.find(:all, :order => 'created_at desc', :conditions => ['login = :login or login = :email', { :login => @showuser.login, :email => @showuser.email }])
            render :template => 'people/admin/showuser'
          end
        else
          # show form
        end
      else
        flash.now[:warning] = 'User not found.'      
        render :template => 'people/admin/showuser'
      end
    else
      flash.now[:warning] = 'Missing user.'      
      render :template => 'people/admin/showuser'
    end    
  end
  
  def invalidemail
    if not params[:id].nil?
      @showuser = User.find_by_login(params[:id])
      if @showuser
          if request.post?
            if params[:reason].nil? or params[:reason].empty?
              flash.now[:failure] = 'A reason for marking this email address invalid is required'      
              @showuser.errors.add("A reason for marking this email address invalid is required")
            else
              if @showuser.invalidemail
                AdminEvent.log_event(@currentuser, AdminEvent::ACCOUNT_INVALIDEMAIL,{:extensionid => @showuser.login, :reason => params[:reason]})
                UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @showuser,:description => "email marked invalid by #{@currentuser.login}")                                                                            
              else
                flash.now[:failure] = 'Failed to mark email invalid, reported status may not be correct'      
              end
              @events = UserEvent.find(:all, :order => 'created_at desc', :conditions => ['login = :login or login = :email', { :login => @showuser.login, :email => @showuser.email }])
              render :template => 'people/admin/showuser'
            end
          else
            # show form
          end
      else
        flash.now[:warning] = 'User not found.'      
        render :template => 'people/admin/showuser'
      end
    else
      flash.now[:warning] = 'Missing user.'      
      render :template => 'people/admin/showuser'
    end    
  end
  
  def index
    @recent_users = User.notsystem_or_admin.validusers.count(:conditions => "created_at > date_sub(curdate(), interval #{AppConfig.configtable['recent_account_delta']} day)")
    @recent_logins = User.notsystem_or_admin.validusers.count(:conditions => "last_login_at > date_sub(curdate(), interval #{AppConfig.configtable['recent_login_delta']} day)")

    @review_users = User.count(:conditions => ["vouched = 0 AND retired = 0 AND emailconfirmed = 1"])
    @retired_accounts = User.count(:conditions => ["retired = 1"])
    @confirmemail_users = User.count(:conditions => ["emailconfirmed = 0 and retired = 0 and account_status != #{User::STATUS_SIGNUP}"])
    @confirmaccount_users = User.count(:conditions => ["account_status = #{User::STATUS_SIGNUP} and retired = 0"])
    @invalidemail_users = User.count(:conditions => ["(account_status = #{User::STATUS_INVALIDEMAIL} or account_status = #{User::STATUS_INVALIDEMAIL_FROM_SIGNUP}) AND retired = 0"])
    
    # @agreement_accepts = User.notsystem_or_admin.validusers.count(:conditions => "contributor_agreement = 1")
    # @agreement_noaccepts = User.notsystem_or_admin.validusers.count(:conditions => "contributor_agreement = 0")
    # @agreement_pending = User.notsystem_or_admin.validusers.count(:conditions => "contributor_agreement is NULL")
    
    @missing = Hash.new
    @missing['location'] = User.notsystem_or_admin.validusers.count(:conditions => "location_id = 0 or location_id is NULL")
    @missing['position'] = User.notsystem_or_admin.validusers.count(:conditions => "position_id = 0 or position_id is NULL")
    
  end
  
  def activity
    if (!params[:days] or (params[:days].to_i == 0))
      @days = AppConfig.configtable['recent_activity_delta']
    else
      @days = params[:days].to_i
    end
    @eventslist = UserEvent.paginate(:all, :order => 'created_at desc', :conditions => "created_at > date_sub(curdate(), interval #{@days} day)",:page => params[:page])      
  end
  
  def agreements
    labels = Hash.new
    findopts = Hash.new
    case params[:type]
    when "accepts"
      labels[:time_column_label] = "agreement entered at"
      labels[:time_column_field] = User::TIMECOLUMN_CONTRIBUTOR_AGREEMENT_AT
      labels[:page_title] = "Users accepting Agreement:"
      findopts[:order] = 'contributor_agreement_at desc'
      findopts[:conditions] = "contributor_agreement = 1"
    when "noaccepts"
      labels[:time_column_label] = "agreement entered at"
      labels[:time_column_field] = User::TIMECOLUMN_CONTRIBUTOR_AGREEMENT_AT
      labels[:page_title] = "Users not acccepting Agreement:"
      findopts[:order] = 'contributor_agreement_at desc'
      findopts[:conditions] = "contributor_agreement = 0"
    when "pending"
      labels[:page_title] = "Users with pending Agreement reviews:"
      findopts[:order] = 'last_name'
      findopts[:conditions] = "contributor_agreement is NULL"
    else
      # uh?
    end
    
    userlist(true,'agreements',labels,findopts,{:type => @type})    
        
  end

  def openidusage
    @opieapprovals = OpieApproval.find(:all)
  end
  
  
  def recent_users
    labels = Hash.new
    findopts = Hash.new
    
    if (!params[:days] or (params[:days].to_i == 0))
      @days = AppConfig.configtable['recent_account_delta']
    else
      @days = params[:days].to_i
    end

    labels[:time_column_label] = "created at"
    labels[:time_column_field] = User::TIMECOLUMN_CREATED_AT
    labels[:page_title] = "Recent Users"
    findopts[:order] = 'created_at desc'
    findopts[:conditions] = "created_at > date_sub(curdate(), interval #{@days} day)"
    userlist(true,'recent_users',labels,findopts)    
  end

  def recent_logins
    labels = Hash.new
    findopts = Hash.new
    
    if (!params[:days] or (params[:days].to_i == 0))
      @days = AppConfig.configtable['recent_login_delta']
    else
      @days = params[:days].to_i
    end
    labels[:time_column_label] = "last login at"
    labels[:time_column_field] = User::TIMECOLUMN_LAST_LOGIN_AT
    labels[:page_title] = "Recent Logins"
    findopts[:order] = 'last_login_at desc'
    findopts[:conditions] = "last_login_at > date_sub(curdate(), interval #{@days} day)"
    userlist(true,'recent_logins',labels,findopts)
  end

  def review_users
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users pending review"
    findopts[:order] = 'updated_at desc'
    findopts[:conditions] = "vouched = 0 AND retired = 0 AND emailconfirmed = 1"
    userlist(false,'review_users',labels,findopts)
  end

  def missing_institution
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users not specifying a institution"
    findopts[:order] = 'last_name'
    findopts[:conditions] = "institution_id = 0 or institution_id is NULL"
    userlist(true,'missing_institution',labels,findopts)
  end
    
  def missing_location
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users not specifying a location"
    findopts[:order] = 'last_name'
    findopts[:conditions] = "location_id = 0 or location_id is NULL"
    userlist(true,'missing_location',labels,findopts)
  end
  
  def missing_position
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users not specifying a position"
    findopts[:order] = 'last_name'
    findopts[:conditions] = "position_id = 0 or position_id is NULL"
    userlist(true,'missing_position',labels,findopts)
  end
  
  def retired_accounts
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Retired accounts"
    findopts[:order] = 'updated_at desc'
    findopts[:conditions] = "retired = 1"
    userlist(false,'retired_accounts',labels,findopts)
  end
  
  def invalidemail_users
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users with invalid email addresses"
    findopts[:order] = 'updated_at desc'
    findopts[:conditions] = "(account_status = #{User::STATUS_INVALIDEMAIL} or account_status = #{User::STATUS_INVALIDEMAIL_FROM_SIGNUP}) and retired = 0"
    userlist(false,'invalidemail_users',labels,findopts)
  end
    
  def confirmemail_users
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users that have not confirmed their email address"
    findopts[:order] = 'updated_at desc'
    findopts[:conditions] = "emailconfirmed = 0 and retired = 0 and account_status != #{User::STATUS_SIGNUP}"
    userlist(false,'confirmemail_users',labels,findopts)
  end  
  
  
  def confirmaccount_users
    labels = Hash.new
    findopts = Hash.new
    
    labels[:page_title] = "Users that have not confirmed their account"
    findopts[:order] = 'updated_at desc'
    findopts[:conditions] = "account_status = #{User::STATUS_SIGNUP} and retired = 0"
    userlist(false,'confirmaccount_users',labels,findopts)
  end
  
  def showuser
    if(!params[:id].nil?)
      if(params[:id].to_i != 0)
        @showuser = User.find_by_id(params[:id])
      else
        @showuser = User.find_by_login(params[:id])
      end
      
      if @showuser   
        @events = UserEvent.find(:all, :order => 'created_at desc', 
          :conditions => ['login = :login or login = :email', { :login => @showuser.login, :email => @showuser.email }])
      else
        flash[:warning] = 'User not found.'      
        render :template => 'people/admin/showuser'
      end
    else
      flash[:warning] = 'Missing user.'      
      render :template => 'people/admin/showuser'
    end
  end
  
  
 
  def finduser
    
    if (params[:searchterm].nil? or params[:searchterm].empty?)
      flash[:warning] = "Empty search term"
      return redirect_to(:action => 'index')
    end
  
  
    @userlist = User.patternsearch(params[:searchterm]).paginate({:order => 'last_name,first_name', :page => params[:page]})
          
    if @userlist.nil? || @userlist.length == 0
      flash[:warning] = "No user was found that matches your search term"
      redirect_to :action => 'index'
    else
      if @userlist.length == 1
        redirect_to :action => :showuser, :id => @userlist[0].login
      end
    end

  end
    
  def fixemail
    # using "showuser" because we include the common/profile view
    @showuser = User.find_by_login(params[:id])
    if @showuser
      if request.post?
        success = @showuser.fix_email(params[:email],@currentuser)
        if(success)
          @showuser.reload
          flash.now[:success] = 'Email address changed, confirmation email sent to ' + @showuser.email + '.'
        else
          flash.now[:success] = 'Unable to change email address for ' + @showuser.login + '.'
        end
        @events = UserEvent.find(:all, :order => 'created_at desc', :conditions => ['login = :login or login = :email', { :login => @showuser.login, :email => @showuser.email }])
        render :template => 'people/admin/showuser'
      end
    else
      flash.now[:warning] = 'User not found.'      
      render :template => 'people/admin/index'
    end  
  end  
  
  private
    
  def csvuserlist(userlist,filename,title)
      @title = title
      @userlist = userlist
      response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
      response.headers['Content-Disposition'] = 'attachment; filename='+filename+'.csv'
      render :template => 'people/common/csvuserlist', :layout => false
  end
   
  def userlist(onlyvalid,action,labels,findopts=nil,otherparams=nil) 
    labels.each do |label,value|
       instance_variable_set("@#{label}",value)
    end
    
    if(findopts.nil?)
      findopts = {:order => 'last_name,first_name'}
    else
      if(!findopts[:order])
        findopts[:order] = 'last_name'
      end
    end
    
  
    if(!params[:downloadreport].nil? and params[:downloadreport] == 'csv')
      reportusers = onlyvalid ? User.notsystem_or_admin.validusers.find(:all, findopts) : User.find(:all, findopts);
      csvfilename =  @page_title.tr(' ','_').gsub('\W','').downcase
      return csvuserlist(reportusers,csvfilename, @page_title)
    else
      findopts[:page] = params[:page]
      @userlist =  onlyvalid ? User.notsystem_or_admin.validusers.paginate(:all, findopts) : User.paginate(:all, findopts);
          
      if((@userlist.length) > 0)
        if(!otherparams.nil?)
          otherparams[:id] = params[:id]
          otherparams[:downloadreport] = 'csv'
        else
          otherparams = {
            :id => params[:id],
            :downloadreport => 'csv'
          }
        end
        @csvreporturl = url_for(:controller => 'people/admin', :action => action, :params => otherparams)
      end
    end
    
    # view variables
    render :template => 'people/admin/users'       
  end  
end