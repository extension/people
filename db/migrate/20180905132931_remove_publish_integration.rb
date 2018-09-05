class RemovePublishIntegration < ActiveRecord::Migration
  def up
    # remove the blogs/publish site from the sites list
    publish_site = Site.where(label: 'blogs').first
    publish_site.destroy
    remove_column(:communities, :blog_id)
  end

  def down
  end
end
