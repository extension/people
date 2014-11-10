# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsUsermeta < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_usermeta'
  self.primary_key = 'umeta_id'

  belongs_to :blogs_user, foreign_key: 'user_id'

  attr_accessible :user_id, :meta_key, :meta_value

end
