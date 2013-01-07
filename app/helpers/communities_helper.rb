# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file
module CommunitiesHelper

  def display_invited_as(connectioncode)
    case connectioncode
    when CommunityConnect::INVITED_LEADER
      'Leader'
    when CommunityConnect::INVITED_MEMBER
      'Member'
    else
      ''
    end
  end


end