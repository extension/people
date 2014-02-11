# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
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

  # the spec says leading 0 is required
  # but the R maps package leaves it as numeric, so I'm doing that
  def fips(make_integer = true)
    if(make_integer)
      fipsid
    else
      "%02d" % fipsid
    end
  end

end