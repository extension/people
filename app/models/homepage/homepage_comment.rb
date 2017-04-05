# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class HomepageComment < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :homepage
  self.table_name='wp_comments'
  self.primary_key = 'comment_ID'

  belongs_to :homepage_user, foreign_key: 'user_id'
  scope :user_activities, lambda{where("user_id > 0").where('comment_approved = 1')}
end
