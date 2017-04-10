# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class HomepageUser < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :homepage
  self.table_name='wp_users'
  self.primary_key = 'ID'
end
