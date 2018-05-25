# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ArticlesPage < ActiveRecord::Base
  # connects to the articles database
  self.establish_connection :articles
  self.table_name= 'pages'
  JOINER = ", "
  SPLITTER = Regexp.new(/\s*,\s*/)

  has_one :articles_link_stat, :foreign_key => "page_id"

  def link_counts
    linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
    if(!self.articles_link_stat.nil?)
      linkcounts.keys.each do |key|
        linkcounts[key] = self.articles_link_stat.send(key)
      end
    end
    return linkcounts
  end

end
