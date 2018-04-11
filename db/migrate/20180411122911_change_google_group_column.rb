class ChangeGoogleGroupColumn < ActiveRecord::Migration
  def change
    add_column(:google_groups, :use_extension_google_accounts, :boolean, null: false, default: false)
    execute "UPDATE google_groups SET use_extension_google_accounts = 1 WHERE use_groups_domain = 0"
    remove_column(:google_groups, :use_groups_domain)
  end
end
