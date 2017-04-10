# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticlesPublishingCommunity < ActiveRecord::Base
  # connects to the darmok database
  self.establish_connection :articles
  self.table_name= 'publishing_communities'
end
