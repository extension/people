# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskGroup < ActiveRecord::Base
  # connects to the aae database
  self.establish_connection :aae
  self.table_name='groups'
end
