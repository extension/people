class CleanupGoogleGroupRelatedItems < ActiveRecord::Migration
  def change
    remove_column(:google_groups, :marked_for_removal)
    remove_column(:communities, :connect_to_google_apps)
  end

  def down
  end
end
