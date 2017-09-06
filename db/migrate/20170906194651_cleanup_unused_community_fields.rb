class CleanupUnusedCommunityFields < ActiveRecord::Migration
  def up
    remove_column(:communities, :public_name)
    remove_column(:communities, :public_description)
    remove_column(:communities, :public_topic_id)
    remove_column(:communities, :is_launched)
    remove_column(:communities, :public_uri)
    remove_column(:communities, :referer_domain)
    remove_column(:communities, :institution_code)
  end
end
