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
  end

  def browse
    #TODO
  end

  def newest
    #TODO
  end

  def connections
    # will raise ActiveRecord::RecordNotFound on not found 
    @community = Community.find_by_shortname_or_id(params[:id])

    # hardcode to joined for now to test
    #TODO FIXME

    @connections = @community.joined.page(params[:page])
  end

  def invitations
    #TODO
  end


end
