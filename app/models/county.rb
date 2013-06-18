# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class County < ActiveRecord::Base
  include CacheTools

  has_many :people
  belongs_to :location

  # the spec says leading 0 is required
  # but the R maps package leaves it as numeric, so I'm doing that
  def fips(make_integer = true)
    if(make_integer)
      "#{state_fipsid}#{countycode}".to_i
    else
      "%02d" % state_fipsid + "#{countycode}"
    end
  end

    
end