# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ResourceTag < ActiveRecord::Base
  has_many :page_taggings
  has_many :pages, :through => :page_taggings
  has_many :analytics, :through => :pages
  has_many :week_stats, :through => :pages  
  has_many :week_diffs, :through => :pages  
  has_many :week_totals
  has_many :published_nodes, :source => :node, :through => :pages
end