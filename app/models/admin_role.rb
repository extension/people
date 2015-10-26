#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AdminRole < ActiveRecord::Base
  attr_accessible :person, :person_id, :applabel

  belongs_to :person

end
