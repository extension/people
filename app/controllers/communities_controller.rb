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

    @connections = @community.connected(connection).page(params[:page])
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
    @person.connect_to_community(@community,params[:connectiontype],{connector: current_person, ip_address: request.remote_ip})
    render(template: 'communities/connection_table_change')    
  end

  def remove_connection
    @community = Community.find_by_shortname_or_id(params[:id])
    @person = Person.find(params[:person_id])
    @person.remove_from_community(@community,{connector: current_person, ip_address: request.remote_ip})
    render(template: 'communities/connection_table_change')       
  end



  private

  def set_tab
    @selected_tab = 'communities'
  end

end
