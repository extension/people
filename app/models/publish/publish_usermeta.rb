# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PublishUsermeta < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :publish
  self.table_name='wp_usermeta'
  self.primary_key = 'umeta_id'

  belongs_to :publish_user, foreign_key: 'user_id'

  attr_accessible :user_id, :meta_key, :meta_value

end
