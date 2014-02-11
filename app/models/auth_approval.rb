# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AuthApproval < ActiveRecord::Base
  belongs_to :person
  attr_accessible :person, :person_id, :trust_root
end