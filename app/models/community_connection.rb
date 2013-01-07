# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class CommunityConnection < ActiveRecord::Base
  belongs_to :community
  belongs_to :person

  # invitation codes
  INVITED_LEADER = 201
  INVITED_MEMBER = 202


  scope :approved_community, joins(:community).where("communities.entrytype = #{Community::APPROVED}")

end