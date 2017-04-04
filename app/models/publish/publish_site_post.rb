# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PublishSitePost < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :publish
  self.table_name='wp_1_posts'
  self.primary_key = 'ID'

  belongs_to :publish_user, foreign_key: 'post_author'

  scope :activity_entries, -> {where("post_type IN ('post','page','revision')").where("post_status != 'future'")}


  def self.repoint(publish_site_id)
    begin
      self.table_name = "wp_#{publish_site_id}_posts"
      self.count
    rescue ActiveRecord::StatementInvalid
      self.table_name = "wp_1_posts"
      nil
    end
  end

end
