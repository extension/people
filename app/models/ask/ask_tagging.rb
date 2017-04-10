# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AskTagging < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :aae
  self.table_name='taggings'

  belongs_to :tag, class_name: 'AskTag', foreign_key: 'tag_id'
end
