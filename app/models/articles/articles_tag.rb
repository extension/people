# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticlesTag < ActiveRecord::Base
  # connects to the articles database
  self.establish_connection :articles
  self.table_name= 'tags'

  has_many :articles_taggings, :foreign_key => "tag_id"
  has_many :articles_communities, :through => :articles_taggings, :source => :articles_publishing_community, :uniq => true



  def self.community_resource_tags
    includes(:articles_taggings).where("taggings.taggable_type = 'PublishingCommunity'").order(:name)
  end

end
