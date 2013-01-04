# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Location < ActiveRecord::Base
  UNKNOWN = 0
  STATE = 1
  INSULAR = 2
  OUTSIDEUS = 3
  
  has_many :people
  has_many :counties
  has_many :communities
  
  scope :states, where(entrytype: STATE)

end