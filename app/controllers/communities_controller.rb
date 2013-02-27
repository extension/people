# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class CommunitiesController < ApplicationController

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

  def invitations
    #TODO
  end


end
