class CleanupGoogleAccountColumns < ActiveRecord::Migration
  def up
    remove_column(:google_accounts, :last_ga_login_request_at)
    remove_column(:google_accounts, :last_google_data)
  end
end
