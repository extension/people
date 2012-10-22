# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Account < ActiveRecord::Base
  belongs_to :county
  belongs_to :location
  belongs_to :position
end