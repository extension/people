# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class CommunitiesController < ApplicationController
  before_filter :set_tab
  skip_before_filter :signin_required, only: [:gallery]
  skip_before_filter :check_hold_status, only: [:gallery]
  before_filter :signin_optional, only: [:gallery]

  def index
    @approved_joined_counts = Community.approved.connected_counts('joined')
  end

  def institutions
    @institutions = Community.institutions.includes(:location,:primary_contact).order(:name)
  end

  def show
    # will raise ActiveRecord::RecordNotFound on not found
    @community = Community.find_by_shortname_or_id(params[:id])
    member_breadcrumbs
    @current_person_community_connection = current_person.connection_with_community(@community)
    @thisconnection = current_person.community_connection(@community)
  end

  def edit
    @community = Community.find(params[:id])
    member_breadcrumbs(['Edit community settings'])

    if(!current_person.can_edit_community?(@community))
      flash[:warning] = "You do not have permission to edit the settings for this community."
      return redirect_to(community_url(@community))
    end
  end

  def update
    @community = Community.find(params[:id])
    if(!current_person.can_edit_community?(@community))
      flash[:warning] = "You do not have permission to edit the settings for this community."
      return redirect_to(community_url(@community))
    end

    # shortname check
    if(!params[:community][:shortname].blank?)
      shortname = params[:community][:shortname]
      if(community = Community.find_by_shortname(shortname) and community.id != @community.id)
        @community.errors.add(:shortname, "That community shortname is already in use.".html_safe)
        return render(:action => "edit")
      elsif(ea = EmailAlias.find_by_mail_alias(shortname) and ea.aliasable != @community)
        @community.errors.add(:shortname, "That shortname is reserved.".html_safe)
        return render(:action => "edit")
      end
    end

    if(@community.update_attributes(params[:community]))
      flash[:notice] = 'Community was successfully updated.'
      Activity.log_activity(person_id: current_person.id, activitycode: Activity::COMMUNITY_UPDATE_INFORMATION, :community => @community, ip_address: request.remote_ip)
      return redirect_to(community_url(@community))
    else
      return render(:action => "edit")
    end
  end

  def new
    collection_breadcrumbs(['Add new community'])
    @community = Community.new
  end

  def create
    @community = Community.new(params[:community])
    @community.entrytype = Community::USERCONTRIBUTED if(!current_person.is_admin?)
    @community.creator = current_person


    # shortname check
    if(!params[:community][:shortname].blank?)
      shortname = params[:community][:shortname]
      if(community = Community.find_by_shortname(shortname))
        @community.errors.add(:shortname, "That community shortname is already in use.".html_safe)
        return render(:action => "new")
      elsif(ea = EmailAlias.find_by_mail_alias(shortname))
        @community.errors.add(:shortname, "That shortname is reserved.".html_safe)
        return render(:action => "new")
      end
    end

    if(@community.save)
      current_person.connect_to_community(@community,'leader',{ip_address: request.remote_ip, nonotify: true}) if(!current_person.is_admin?)
      flash[:notice] = 'Community was successfully created.'
      Activity.log_activity(person_id: current_person.id, activitycode: Activity::COMMUNITY_CREATE, :community => @community, ip_address: request.remote_ip)
      return redirect_to(community_url(@community))
    else
      return render(:action => "new")
    end
  end

  def newest
    collection_breadcrumbs(['List (by creation time)'])
    @communities = Community.order('created_at DESC').page(params[:page])
  end

  def contacts
    collection_breadcrumbs(['eXtension Community of Practice Contacts'])
    @communities = Community.approved.order('name')
  end

  def connectionsfile
    # will raise ActiveRecord::RecordNotFound on not found
    @community = Community.find_by_shortname_or_id(params[:id])
    filename = "#{Settings.downloads_data_dir}/community_#{@community.id}_connections.csv"
    @community.people.display_accounts.dump_to_csv(filename,{community: @community})
    send_file(filename,
              :type => 'text/csv; charset=iso-8859-1; header=present',
              :disposition => "attachment; filename=#{File.basename(filename)}")
  end

  def connections
    # will raise ActiveRecord::RecordNotFound on not found
    @community = Community.find_by_shortname_or_id(params[:id])
    allowed_connections = Community::CONNECTION_CONDITIONS.keys
    if(params[:connection] and allowed_connections.include?(params[:connection]))
      connection = params[:connection]
    else
      connection = 'joined'
    end

    if (@community.is_institution? and connection == 'leaders')
      member_breadcrumbs(["Connections (Institutional Team)"])
    else
      member_breadcrumbs(["Connections (#{connection.capitalize})"])
    end

    @connections = @community.connected(connection).order('people.last_name').page(params[:page])
  end

  def gallery
    @no_show_navtabs = true
    @community = Community.find_by_shortname_or_id(params[:id])
    if(current_person)
      @connections = @community.connected('joined').order('people.last_name')
    else
      store_location
      @connections = @community.joined_with_public_avatar.order('people.last_name')
    end
    return render(layout: 'public')
  end

  def setmasthead
    @community = Community.find_by_shortname_or_id(params[:id])
    if(params[:delete] and TRUE_VALUES.include?(params[:delete]))
      @community.remove_community_masthead!
      @community.save
    else
      update_params = params[:community]
      if(!update_params['community_masthead'].blank?)
        @community.update_attributes(update_params)
      end
    end
    Activity.log_activity(person_id: current_person.id, activitycode: Activity::COMMUNITY_UPDATE_INFORMATION, :community => @community, ip_address: request.remote_ip)
    return redirect_to gallery_community_path(@community)
  end

  def invite
    @community = Community.find_by_shortname_or_id(params[:id])
    member_breadcrumbs(['Invite colleagues'])

    if (!params[:q].blank?)
      @connections = Person.display_accounts.patternsearch(params[:q]).order('last_name,first_name').page(params[:page])
      if @connections.blank?
        flash[:warning] = "No colleagues were found that matched your search term"
      end
    end

  end


  def join
    @community = Community.find_by_shortname_or_id(params[:id])
    current_person.join_community(@community,{ip_address: request.remote_ip})
    @current_person_community_connection = current_person.connection_with_community(@community)
    @thisconnection = current_person.community_connection(@community)
    render(template: 'communities/connect')
  end

  def leave
    @community = Community.find_by_shortname_or_id(params[:id])
    current_person.leave_community(@community,{ip_address: request.remote_ip})
    @current_person_community_connection = current_person.connection_with_community(@community)
    @thisconnection = current_person.community_connection(@community)
    render(template: 'communities/connect')
  end

  def change_connection
    @community = Community.find_by_shortname_or_id(params[:id])
    @person = Person.find(params[:person_id])
    @person.connect_to_community(@community,params[:connectiontype],{connector_id: current_person.id, ip_address: request.remote_ip})
    render(template: 'communities/connection_table_change')
  end

  def remove_connection
    @community = Community.find_by_shortname_or_id(params[:id])
    @person = Person.find(params[:person_id])
    @person.remove_from_community(@community,{connector_id: current_person.id, ip_address: request.remote_ip})
    render(template: 'communities/connection_table_change')
  end

  def find
    collection_breadcrumbs(['Find communities'])

    if (!params[:q].blank?)
      @found_communities = Community.findcommunity(params[:q])
      if(@found_communities.blank?)
        flash[:warning] = "No community was found that matches your search term"
      elsif(@found_communities.length == 1)
        return redirect_to(community_url(@found_communities[0]))
      end
    end
  end

  def activity
    if(params[:id])
      @community = Community.find_by_shortname_or_id(params[:id])
      member_breadcrumbs(['Activity'])

      @activities = @community.activities.order('created_at DESC').page(params[:page])
    else
      collection_breadcrumbs(['Activity'])
      @activities = Activity.community.order('created_at DESC').page(params[:page])
    end
  end


  def change_notification
    @thisconnection = CommunityConnection.find(params[:id])
    @community = @thisconnection.community
    if (@thisconnection.person == current_person)
      if(!params[:is_on].nil? and params[:is_on] == 'yes')
        @thisconnection.update_attributes({sendnotifications: true})
      else
        @thisconnection.update_attributes({sendnotifications: false})
      end
    end
  end

  private

  def member_breadcrumbs(endpoints = [])
    add_breadcrumb("Communities", :communities_path)
    add_breadcrumb("#{@community.name}", community_path(@community))
    if(!endpoints.blank?)
      endpoints.each do |endpoint|
        if(endpoint.is_a?(Array))
          add_breadcrumb(endpoint[0],endpoint[1])
        else
          add_breadcrumb(endpoint)
        end
      end
    end
  end

  def collection_breadcrumbs(endpoints = [])
    add_breadcrumb("Communities", :communities_path)
    if(!endpoints.blank?)
      endpoints.each do |endpoint|
        if(endpoint.is_a?(Array))
          add_breadcrumb(endpoint[0],endpoint[1])
        else
          add_breadcrumb(endpoint)
        end
      end
    end
  end

  def set_tab
    @selected_tab = 'communities'
  end

end
