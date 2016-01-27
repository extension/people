# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskTag < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :aae
  self.table_name='tags'

  has_many :taggings, class_name: 'AskTagging', foreign_key: 'tag_id'

end
