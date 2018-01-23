class ChangeGoogleGroups < ActiveRecord::Migration
  def change
    remove_column(:google_groups, :last_error)
    add_column(:google_groups, :last_api_request, :integer)
    add_column(:google_groups, :use_groups_domain, :boolean, null: false, default: false)
  end
end
