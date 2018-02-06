# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class CommunityConnection < ActiveRecord::Base
  attr_accessible :person,:person_id,:community,:community_id,:connector,:connected_by,:connectiontype,:sendnotifications

  belongs_to :community, unscoped: true
  belongs_to :person

  scope :approved_community, ->{joins(:community).where("communities.entrytype = #{Community::APPROVED}")}
  scope :joined_connections, ->{where(Community::CONNECTION_CONDITIONS['joined'])}

end
