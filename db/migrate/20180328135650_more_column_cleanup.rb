class MoreColumnCleanup < ActiveRecord::Migration
  def up
    remove_column(:google_groups, :lists_alias)
  end
end
