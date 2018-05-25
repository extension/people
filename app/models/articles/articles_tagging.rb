# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticlesTagging < ActiveRecord::Base
  # connects to the articles database
  self.establish_connection :articles
  self.table_name= 'taggings'

  # tagging_kinds
  GENERIC = 0  # table defaults
  USER = 1
  SHARED = 2
  CONTENT = 3
  CONTENT_PRIMARY = 4  # for public communities, indicates the primary content tag for the community, if more than one

  belongs_to :articles_publishing_community, :foreign_key => "taggable_id", :conditions => "taggable_type = 'PublishingCommunity'"

  scope :page_content, where("taggable_type = 'Page'")


end
