# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class HomepagePost < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :homepage
  self.table_name='wp_posts'
  self.primary_key = 'ID'

  belongs_to :homepage_user, foreign_key: 'post_author'

  scope :activity_entries, -> {where("post_type IN ('post','page','revision')").where("post_status != 'future'")}

end
