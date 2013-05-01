# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AuthApproval < ActiveRecord::Base
  belongs_to :person
  attr_accessible :person, :person_id, :trust_root

  # TODO add a host whitelist for things to be auto-approved
end