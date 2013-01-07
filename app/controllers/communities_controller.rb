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
  end

end
