# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class CommunitiesController < ApplicationController
  before_filter :set_tab

  def index
    @approved_joined_counts = Community.approved.connected_counts('joined')
  end

  def show
    # will raise ActiveRecord::RecordNotFound on not found 
    @community = Community.find_by_shortname_or_id(params[:id])
    @current_person_community_connection = current_person.connection_with_community(@community)
  end

  def edit
    @community = Community.find(params[:id])
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
    @communities = Community.order('created_at DESC').page(params[:page])
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

    @connections = @community.connected(connection).order('people.last_name').page(params[:page])
  end

  def invite
    @community = Community.find_by_shortname_or_id(params[:id])

    if (!params[:q].blank?) 
      @connections = Person.patternsearch(params[:q]).order('last_name,first_name').page(params[:page])
      if @connections.blank?
        flash[:warning] = "No colleagues were found that matched your search term"
      end
    end
    
  end


  def join
    @community = Community.find_by_shortname_or_id(params[:id])
    current_person.join_community(@community,{ip_address: request.remote_ip})
    @current_person_community_connection = current_person.connection_with_community(@community)
    render(template: 'communities/connect')
  end

  def leave
    @community = Community.find_by_shortname_or_id(params[:id])
    current_person.leave_community(@community,{ip_address: request.remote_ip})
    @current_person_community_connection = current_person.connection_with_community(@community)
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
    if (!params[:q].blank?)
      @current_person_communities = current_person.connected_communities
      @found_communities = Community.findcommunity(params[:q])
      if(@found_communities.blank?)
        flash[:warning] = "No community was found that matches your search term"
      elsif(@found_communities.length == 1)
        return redirect_to(community_url(@found_communities[0]))
      end
    end
  end


  private

  def set_tab
    @selected_tab = 'communities'
  end

end
