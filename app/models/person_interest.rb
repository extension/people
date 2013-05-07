# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file
require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning

class PersonInterest < ActiveRecord::Base
  attr_accessible :interest, :interest_id, :person, :person_id

  belongs_to :interest
  belongs_to :person

  
end