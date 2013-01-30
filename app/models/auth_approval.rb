# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class AuthApproval < ActiveRecord::Base
  belongs_to :person

  # TODO add a host whitelist for things to be auto-approved
end